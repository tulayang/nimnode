#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright. 

## This module implements a duplex (readable, writable) stream based on libuv. A
## stream is an abstract interface which provides reading and writing for 
## non-blocking I/O.

import uv, error, nettype

when defined(nodeBufSize):
  const BufSize* = nodeBufSize
else:
  const BufSize* = 4 * 1024

when defined(nodeWriteOverLevel):
  const WriteOverLevel* = nodeWriteOverLevel
else:
  const WriteOverLevel* = 16 * 1024 

type
  StreamReader = object
    buf: array[BufSize, char]
    bufLen: int

  StreamWriter = object
    req: Write
    buf: seq[tuple[base: pointer, length: int, cb: proc (err: ref NodeError) {.closure, gcsafe.}]]
    bufLen: int
    bufQueueSize: int
    bufWritingSize: int
    writingCb: proc (err: ref NodeError) {.closure, gcsafe.}

  StreamStat = enum   
    statClosed, statClosing, 
    statRDFlowing, statRDStoped, statRDEnded, statRDEndEmitted, 
    statWRReady, statWRNeedDrain, statWRWriting, statWRCorked, statWREnded, statWREndEmitted

  UvStream* = ref object of RootObj
    onData*: proc (data: pointer, size: int) {.closure, gcsafe.}
    onEnd*: proc () {.closure, gcsafe.}
    onDrain*: proc () {.closure, gcsafe.}
    onFinish*: proc () {.closure, gcsafe.}
    onClose*: proc (err: ref NodeError) {.closure, gcsafe.}
    onCloseHook: proc (err: ref NodeError) {.closure, gcsafe.}
    reader: StreamReader
    writer: StreamWriter
    shutdown: Shutdown
    stats: set[StreamStat]
    handle: Stream
    error: ref NodeError

template offsetChar(x: pointer, i: int): pointer =
  cast[pointer](cast[ByteAddress](x) + i * sizeof(char))

proc closeCb(handle: ptr Handle) {.cdecl.} =
  var stream = cast[UvStream](handle.data)
  GC_unref(stream)
  # for writing 
  if stream.writer.writingCb != nil:
    stream.writer.writingCb(stream.error)
  # for buffer
  for i in 0..<stream.writer.bufLen:
    let cb = stream.writer.buf[i].cb
    if cb != nil:
      cb(stream.error)
  setLen(stream.writer.buf, 0)
  stream.writer.bufLen = 0
  stream.writer.bufQueueSize = 0
  stream.writer.bufWritingSize = 0
  stream.writer.writingCb = nil
  stream.reader.bufLen = 0
  if stream.onCloseHook != nil:
    stream.onCloseHook(stream.error)
  if stream.onClose != nil:
    stream.onClose(stream.error)
  elif stream.error != nil:
    raise stream.error

proc close*(stream: UvStream) =
  ## Close ``stream``. Handles that wrap file descriptors are closed immediately.
  if statClosed notin stream.stats:
    excl(stream.stats, statClosing)
    incl(stream.stats, statClosed)
    close(cast[ptr Handle](addr(stream.handle)), closeCb)

proc shutdownCb(req: ptr Shutdown, status: cint) {.cdecl.} =
  let stream = cast[UvStream](cast[ptr Stream](req.handle).data) 
  incl(stream.stats, statWREndEmitted)
  let err = status
  if err < 0:
    stream.error = newNodeError(err)
    close(stream)
  else:
    if stream.onFinish != nil:
      stream.onFinish() 
    if statClosing in stream.stats or statRDEndEmitted in stream.stats:
      close(stream)

proc doClear(stream: UvStream): cint {.gcsafe.}

proc writeEnd*(stream: UvStream) = 
  ## Shutdown the outgoing (write) side and waits for all pending write requests to complete.
  if statClosed  notin stream.stats and 
     statWREnded notin stream.stats: 
    incl(stream.stats, statWREnded)
    if statWRCorked in stream.stats:
      excl(stream.stats, statWRCorked)
    if statWRReady    in   stream.stats and 
       statWRWriting notin stream.stats and 
       stream.writer.bufLen > 0:
      incl(stream.stats, statWRWriting)
      let err = doClear(stream)
      if err < 0:
        stream.error = newNodeError(err)
        close(stream)
        return
    let err = shutdown(addr(stream.shutdown), 
                       cast[ptr Stream](addr(stream.handle)), shutdownCb)
    if err < 0:
      stream.error = newNodeError(err)
      close(stream)

proc closeSoon*(stream: UvStream) = 
  ## Shutdown the outgoing (write) side. After all pending write requests 
  ## are completed, close the ``stream``.
  if statClosed  notin stream.stats and 
     statClosing notin stream.stats:
    incl(stream.stats, statClosing)
    if statWREnded notin stream.stats:
      writeEnd(stream)
    elif statWREndEmitted notin stream.stats:
      discard # shutdown, wait for shutdownCb
    else:
      close(stream)
    assert statWREnded in stream.stats

proc allocCb(handle: ptr Handle, size: csize, buf: ptr Buffer) {.cdecl.} =
  let stream = cast[UvStream](handle.data)
  buf.base = offsetChar(stream.reader.buf[0].addr, stream.reader.bufLen) 
  buf.length = BufSize - stream.reader.bufLen

proc readCb(handle: ptr Stream, nread: cssize, buf: ptr Buffer) {.cdecl.} =
  if nread == 0: # EINTR or EAGAIN or EWOULDBLOCK
    return
  let stream = cast[UvStream](handle.data)
  if nread < 0:
    if cint(nread) == uv.EOF:
      incl(stream.stats, statRDEnded)
      if statRDFlowing in stream.stats:
        incl(stream.stats, statRDEndEmitted)
        if stream.onEnd != nil:
          stream.onEnd()
        if statWREndEmitted in stream.stats:
          close(stream)
      ##############################
      # if not stream.allowHalfOpen:
      #   if statWREndEmitted in stream.stats:
      #     stream.close()
      #   elif statWriteEnd in stream.stats:
      #     discard
      #   else:
      #     stream.endSoon()
      # else:
      #   if statWREndEmitted in stream.stats:
      #     stream.close()
      ####################
    else:
      stream.error = newNodeError(cint(nread))
      close(stream)
  else:
    if statRDFlowing in stream.stats:
      if stream.onData != nil:
        stream.onData(addr(stream.reader.buf[0]), int(cint(nread)))
        stream.reader.bufLen = 0
    else:
      inc(stream.reader.bufLen, int(cint(nread)))
      if stream.reader.bufLen >= BufSize:
        let err = readStop(cast[ptr Stream](addr(stream.handle)))
        if err < 0:
          stream.error = newNodeError(err)
          close(stream)
        else:
          incl(stream.stats, statRDStoped)    

proc readResume*(stream: UvStream) =
  if statRDFlowing notin stream.stats:
    incl(stream.stats, statRDFlowing)
    if statClosed  notin stream.stats and 
       statClosing notin stream.stats:
      if statRDEnded in stream.stats:
        if statRDEndEmitted notin stream.stats:
          incl(stream.stats, statRDEndEmitted)
          if stream.onEnd != nil:
            stream.onEnd()
          if statWREndEmitted in stream.stats:
            close(stream)
      else:
        if statRDStoped in stream.stats:
          let err = readStart(cast[ptr Stream](addr(stream.handle)), allocCb, readCb)
          if err < 0:
            stream.error = newNodeError(err)
            close(stream)
          else:
            excl(stream.stats, statRDStoped)
            if stream.reader.bufLen > 0:
              assert stream.reader.bufLen == BufSize
              stream.onData(addr(stream.reader.buf[0]), stream.reader.bufLen)
              stream.reader.bufLen = 0  

proc readPause*(stream: UvStream) =
  excl(stream.stats, statRDFlowing)

proc writeCb(req: ptr Write, status: cint) {.cdecl.} =
  let stream = cast[UvStream](cast[ptr Stream](req.handle).data) 
  if status < 0:
    stream.error = newNodeError(status)
    close(stream)
  else:
    assert statClosed notin stream.stats
    dec(stream.writer.bufQueueSize, stream.writer.bufWritingSize)
    stream.writer.bufWritingSize = 0
    if stream.writer.bufQueueSize == 0 and statWRNeedDrain in stream.stats:
      excl(stream.stats, statWRNeedDrain)
      if stream.onDrain != nil:
        stream.onDrain()
    if stream.writer.writingCb != nil:
      stream.writer.writingCb(nil)
      stream.writer.writingCb = nil
    if stream.writer.bufLen > 0 and (statWREnded in stream.stats or statWRCorked notin stream.stats):
      let err = doClear(stream)
      if err < 0:
        stream.error = newNodeError(err)
        close(stream)
    else:
      excl(stream.stats, statWRWriting)

proc doWrite(stream: UvStream, buf: pointer, size: int, 
             cb: proc (err: ref NodeError) {.closure, gcsafe.}): cint =
  var buffer = Buffer()
  buffer.base = buf
  buffer.length = size
  stream.writer.req = Write()
  stream.writer.writingCb = cb
  stream.writer.bufWritingSize = size
  return write(addr(stream.writer.req), cast[ptr Stream](addr(stream.handle)), 
               addr(buffer), 1, writeCb)

proc doWrite(stream: UvStream): cint =
  assert stream.writer.bufLen > 1
  let n = stream.writer.bufLen
  var bufWritingSize = 0
  var bufs = cast[ptr Buffer](alloc(n * sizeof(Buffer)))
  var cbs = newSeqOfCap[proc (err: ref NodeError) {.closure, gcsafe.}](n)
  for i in 0..<n:
    var buf = cast[ptr Buffer](cast[ByteAddress](bufs) + i * sizeof(Buffer))
    buf.base = stream.writer.buf[i].base
    buf.length = stream.writer.buf[i].length
    add(cbs, stream.writer.buf[i].cb)
    inc(bufWritingSize, stream.writer.buf[i].length)
  stream.writer.req = Write()
  let err = write(addr(stream.writer.req), cast[ptr Stream](addr(stream.handle)), 
                  bufs, cuint(n), writeCb)
  if err < 0:
    dealloc(bufs)
  else:
    GC_ref(cbs)
    stream.writer.writingCb = proc (err: ref NodeError) =
      for cb in cbs:
        if cb != nil:
          cb(err)
      GC_unref(cbs)
      cbs = nil
      dealloc(bufs)
    stream.writer.bufWritingSize = bufWritingSize

proc doClear(stream: UvStream): cint =
  assert stream.writer.bufLen > 0
  if stream.writer.bufLen == 1:
    let err = doWrite(stream, stream.writer.buf[0].base, 
                      stream.writer.buf[0].length, stream.writer.buf[0].cb)
    if err < 0:
      return err
  else:
    let err = doWrite(stream)
    if err < 0:
      return err
  setLen(stream.writer.buf, 0)
  stream.writer.bufLen = 0

proc write*(stream: UvStream, buf: pointer, size: int, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  if statClosed  in stream.stats or 
     statWREnded in stream.stats:
    stream.error = newNodeError(ENOD_WREND)
    if cb != nil:
      cb(stream.error)
    close(stream)
  elif statWRWriting in  stream.stats or 
       statWRCorked  in  stream.stats or 
       statWRReady notin stream.stats: 
    add(stream.writer.buf, (base: buf, length: size, cb: cb))
    inc(stream.writer.bufLen)
    inc(stream.writer.bufQueueSize, size)   
    if stream.writer.bufQueueSize >= WriteOverLevel:
      incl(stream.stats, statWRNeedDrain)
  else:
    assert stream.writer.bufLen == 0
    incl(stream.stats, statWRWriting)
    let err = doWrite(stream, buf, size, cb)
    if err < 0:
      stream.error = newNodeError(err)
      close(stream)
    else:
      inc(stream.writer.bufQueueSize, size)   
      if stream.writer.bufQueueSize >= WriteOverLevel:
        incl(stream.stats, statWRNeedDrain)

proc write*(stream: UvStream, buf: string, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  ## Writes ``buf`` to ``stream``. 
  GC_ref(buf)
  write(stream, buf.cstring, buf.len) do (err: ref NodeError):
    GC_unref(buf)
    if cb != nil:
      cb(err)

proc writeCork*(stream: UvStream) =
  incl(stream.stats, statWRCorked)

proc writeUncork*(stream: UvStream) = 
  if statWRCorked in stream.stats:
    excl(stream.stats, statWRCorked)
    if statClosed    notin stream.stats and 
       statWREnded   notin stream.stats and 
       statWRReady   in    stream.stats and 
       statWRWriting notin stream.stats and
       stream.writer.bufLen > 0 :
      incl(stream.stats, statWRWriting)
      let err = doClear(stream)
      if err < 0:
        stream.error = newNodeError(err)
        close(stream)

proc isFlowing*(stream: UvStream): bool =
  result = statRDFlowing in stream.stats

proc isNeedDrain*(stream: UvStream): bool =
  result = statWRNeedDrain in stream.stats

proc failed*(stream: UvStream): bool = 
  result = stream.error != nil

proc error*(stream: UvStream): ref NodeError = 
  result = stream.error

type
  TcpSocket* = ref object of UvStream ## Abstraction of TCP connection. 
    onConnect*: proc () {.closure, gcsafe.}

proc newTcpSocket(): TcpSocket =
  ## Create a new TCP connection.
  new(result)
  GC_ref(result) 
  result.writer.buf = @[]
  result.stats = {statRDStoped}
  let err = init(getDefaultLoop(), cast[ptr Tcp](addr(result.handle)))
  if err < 0:
    result.error = newNodeError(err)
    close(result)  
  else:
    result.handle.data = cast[pointer](result)

proc connectCb(req: ptr Connect, status: cint) {.cdecl.} =
  let sock = cast[TcpSocket](req.data)
  dealloc(req)
  if status < 0:
    sock.error = newNodeError(status)
    close(sock)
  else:
    incl(sock.stats, statWRReady)
    if sock.onConnect != nil:
      sock.onConnect()

proc connect*(port: Port, hostname = "127.0.0.1", domain = Domain.AF_INET): TcpSocket =
  ## Establishs an IPv4 or IPv6 TCP connection and returns a fresh ``TcpSocket``.
  template condFree(exp: untyped): untyped =
    let err = exp
    if err < 0:
      uv.freeAddrInfo(addrReq.addrInfo)
      dealloc(connectReqPtr)
      result.error = newNodeError(err)
      close(result)
      return
  result = newTcpSocket()
  if not result.failed:
    var connectReqPtr = cast[ptr Connect](alloc0(sizeof(Connect)))
    var addrReq: GetAddrInfo
    var hints: uv.AddrInfo
    hints.ai_family = cint(domain)
    hints.ai_socktype = 0
    hints.ai_protocol = 0
    condFree getAddrInfo(getDefaultLoop(), addr(addrReq), nil, 
                         hostname, $(int(port)), addr(hints))
    connectReqPtr.data = cast[pointer](result)
    condFree connect(connectReqPtr, cast[ptr Tcp](addr(result.handle)),
                     addrReq.addrInfo.ai_addr, connectCb)
    uv.freeAddrInfo(addrReq.addrInfo) 
    readResume(result) 

proc accept*(server: ptr Tcp, 
             cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil): TcpSocket = 
  result = newTcpSocket()
  result.onCloseHook = cb
  if not result.failed:
    let err = accept(cast[ptr Stream](server), cast[ptr Stream](addr(result.handle)))
    if err < 0:
      result.error = newNodeError(err)
      close(result)
    else:
      incl(result.stats, statWRReady)
      readResume(result) 






