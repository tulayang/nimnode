#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright. 

## This module provides an abstraction of a duplex communication based on libuv. 
## ``NodeStream`` is an abstract interface which provides reading and writing for 
## non-blocking I/O.
## 
## There are 3 duplex implementations in the form of ``TcpStream``, ``TtyStream``, 
## ``PipeStream``.

import uv, error, nativesockets

when defined(nodeBufSize):
  const BufSize* = nodeBufSize
else:
  const BufSize* = 4 * 1024

when defined(nodeWriteOverLevel):
  const WriteOverLevel* = nodeWriteOverLevel
else:
  const WriteOverLevel* = 16 * 1024 

type
  StreamStat = enum   
    statClosed, statWaitingClosed, 
    statFlowing, statReading, statReadEnded, statReadEndEmitted, 
    statWriteReady, statWriteNeedDrain, statWriting, statWriteEnded, statWriteEndEmitted

  NodeStream* = ref object of RootObj ## Abstract interface are both readable and writable. 
    handle: Stream
    readBuf: array[BufSize, char]
    readBufLen: int
    readCb: proc (data: pointer, size: int) {.closure, gcsafe.}
    readEndCb: proc () {.closure, gcsafe.}
    writeBuf: seq[tuple[base: pointer, length: int, cb: proc (err: ref NodeError) {.closure, gcsafe.}]]
    writeBufLen: int
    writeQueueSize: int
    writeCorks: int
    writeDrainCb: proc () {.closure, gcsafe.}
    writeEndCb: proc () {.closure, gcsafe.}
    writingReq: Write
    writingSize: int
    writingCb: proc (err: ref NodeError) {.closure, gcsafe.}
    shutdown: Shutdown
    closeCb: proc (err: ref NodeError) {.closure, gcsafe.}
    closeHandCb: proc (err: ref NodeError) {.closure, gcsafe.}
    error: ref NodeError
    stats: set[StreamStat]

proc `onRead=`*(S: NodeStream, cb: proc (data: pointer, size: int) {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when reading a chunk of data.
  S.readCb = cb

proc `onReadEnd=`*(S: NodeStream, cb: proc () {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when reading the end of file.
  S.readEndCb = cb

proc `onWriteDrain=`*(S: NodeStream, cb: proc () {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when writing buffers is become empty from large than ``WriteOverLevel``.
  S.writeDrainCb = cb

proc `onWriteEnd=`*(S: NodeStream, cb: proc () {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when the write side is shutdowned.
  S.writeEndCb = cb

proc `onClose=`*(S: NodeStream, cb: proc (err: ref NodeError) {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when the stream is closed. If an error occurs, the callback will
  ##  be called with the error as its first argument.
  S.closeCb = cb

template offsetChar(x: pointer, i: int): pointer =
  cast[pointer](cast[ByteAddress](x) + i * sizeof(char))

proc clearRead(S: NodeStream) =
  S.readBufLen = 0

proc clearWrite(S: NodeStream) =
  # if there is writing request
  if S.writingCb != nil:
    S.writingCb(S.error)
    S.writingCb = nil
  # if there are still unprocessed write requests
  for i in 0..<S.writeBufLen:
    let cb = S.writeBuf[i].cb
    if cb != nil:
      cb(S.error)
  setLen(S.writeBuf, 0)
  S.writeBufLen = 0
  S.writeQueueSize = 0
  S.writingSize = 0
  S.writeCorks = 0

proc closeCb(handle: ptr Handle) {.cdecl.} =
  var S = cast[NodeStream](handle.data)
  GC_unref(S)
  if S.closeHandCb != nil:
    S.closeHandCb(S.error)
  if S.closeCb != nil:
    S.closeCb(S.error)
  elif S.error != nil:
    raise S.error

proc close*(S: NodeStream) =
  ## Close ``S``. Handles that wrap file descriptors are closed immediately.
  if statClosed notin S.stats:
    incl(S.stats, statClosed)
    clearRead(S)
    clearWrite(S)
    close(cast[ptr Handle](addr(S.handle)), closeCb)

proc shutdownCb(req: ptr Shutdown, status: cint) {.cdecl.} =
  let S = cast[NodeStream](cast[ptr Stream](req.handle).data) 
  incl(S.stats, statWriteEndEmitted)
  let err = status
  if err < 0:
    S.error = newNodeError(err)
    close(S)
  else:
    if S.writeEndCb != nil:
      S.writeEndCb() 
    if statWaitingClosed in S.stats or statReadEndEmitted in S.stats:
      close(S)

proc doClearBuf(S: NodeStream): cint {.gcsafe.}

proc writeEnd*(S: NodeStream) = 
  ## Shutdown the outgoing (write) side and waits for all pending write requests to complete.
  if statClosed     notin S.stats and 
     statWriteEnded notin S.stats: 
    incl(S.stats, statWriteEnded)
    if S.writeCorks > 0:
      S.writeCorks = 0 # Remove the cork, write out all
    if statWriteReady in    S.stats and 
       statWriting    notin S.stats and 
       S.writeBufLen > 0:
      let err = doClearBuf(S)
      if err < 0:
        S.error = newNodeError(err)
        close(S)
        return
      incl(S.stats, statWriting)
    let err = shutdown(addr(S.shutdown), 
                       cast[ptr Stream](addr(S.handle)), shutdownCb)
    if err < 0:
      S.error = newNodeError(err)
      close(S)

proc closeSoon*(S: NodeStream) = 
  ## Shutdown the outgoing (write) side and waits for all pending write requests to complete.
  ## After that, close ``S``.
  if statClosed  notin S.stats and 
     statWaitingClosed notin S.stats:
    incl(S.stats, statWaitingClosed)
    if statWriteEnded notin S.stats:
      writeEnd(S)
    elif statWriteEndEmitted notin S.stats:
      discard # shutdown, wait for shutdownCb
    else:
      close(S)
    assert statWriteEnded in S.stats

proc writingCb(req: ptr Write, status: cint) {.cdecl.} =
  let S = cast[NodeStream](cast[ptr Stream](req.handle).data) 
  if status < 0:
    S.error = newNodeError(status)
    close(S)
  else:
    assert statClosed  notin S.stats
    assert statWriting in    S.stats
    dec(S.writeQueueSize, S.writingSize)
    S.writingSize = 0
    if S.writeQueueSize == 0 and statWriteNeedDrain in S.stats:
      excl(S.stats, statWriteNeedDrain)
      if S.writeDrainCb != nil:
        S.writeDrainCb()
    if S.writingCb != nil:
      S.writingCb(nil)
      S.writingCb = nil
    if S.writeBufLen > 0 and (statWriteEnded in S.stats or S.writeCorks <= 0):
      let err = doClearBuf(S)
      if err < 0:
        S.error = newNodeError(err)
        close(S)
    else:
      excl(S.stats, statWriting)

proc doWriteData(S: NodeStream, buf: pointer, size: int, 
                 cb: proc (err: ref NodeError) {.closure, gcsafe.}): cint =
  var buffer = Buffer()
  buffer.base = buf
  buffer.length = size
  S.writingReq = Write()
  S.writingCb = cb
  S.writingSize = size
  result = write(addr(S.writingReq), cast[ptr Stream](addr(S.handle)), 
                 addr(buffer), 1, writingCb)

proc doWriteBuf(S: NodeStream): cint =
  assert S.writeBufLen > 1
  let n = S.writeBufLen
  var writingSize = 0
  var bufs = cast[ptr Buffer](alloc(n * sizeof(Buffer)))
  var cbs = newSeqOfCap[proc (err: ref NodeError) {.closure, gcsafe.}](n)
  for i in 0..<n:
    var buf = cast[ptr Buffer](cast[ByteAddress](bufs) + i * sizeof(Buffer))
    buf.base = S.writeBuf[i].base
    buf.length = S.writeBuf[i].length
    add(cbs, S.writeBuf[i].cb)
    inc(writingSize, S.writeBuf[i].length)
  S.writingReq = Write()
  result = write(addr(S.writingReq), cast[ptr Stream](addr(S.handle)), 
                 bufs, cuint(n), writingCb)
  if result < 0:
    dealloc(bufs)
  else:
    GC_ref(cbs)
    S.writingCb = proc (err: ref NodeError) =
      for cb in cbs:
        if cb != nil:
          cb(err)
      GC_unref(cbs)
      cbs = nil
      dealloc(bufs)
    S.writingSize = writingSize

proc doClearBuf(S: NodeStream): cint =
  assert S.writeBufLen > 0
  if S.writeBufLen == 1:
    let err = doWriteData(S, S.writeBuf[0].base, 
                          S.writeBuf[0].length, S.writeBuf[0].cb)
    if err < 0:
      return err
  else:
    let err = doWriteBuf(S)
    if err < 0:
      return err
  setLen(S.writeBuf, 0)
  S.writeBufLen = 0
  return 0

proc addWriteBuf(S: NodeStream, buf: pointer, size: int, 
                 cb: proc (err: ref NodeError) {.closure, gcsafe.}) =
  add(S.writeBuf, (base: buf, length: size, cb: cb))
  inc(S.writeBufLen)
  inc(S.writeQueueSize, size)   
  if S.writeQueueSize >= WriteOverLevel:
    incl(S.stats, statWriteNeedDrain)

proc write*(S: NodeStream, buf: pointer, size: int, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  ## Writes data to the underlying system, and calls the supplied callback once the data has been fully 
  ## handled. If an error occurs, the callback will be called with the error as its first argument.
  if statClosed     in S.stats or 
     statWriteEnded in S.stats:
    S.error = newNodeError(END_WREND)
    if cb != nil:
      cb(S.error)
    close(S)
  elif statWriting    in    S.stats or 
       statWriteReady notin S.stats or
       S.writeCorks > 0: 
    addWriteBuf(S, buf, size, cb)
  else:
    assert S.writeBufLen == 0
    let err = doWriteData(S, buf, size, cb)
    if err < 0:
      S.error = newNodeError(err)
      close(S)
    else:
      incl(S.stats, statWriting)
      inc(S.writeQueueSize, size)   
      if S.writeQueueSize >= WriteOverLevel:
        incl(S.stats, statWriteNeedDrain)

proc write*(S: NodeStream, buf: string, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  ## Writes data to the underlying system, and calls the supplied callback once the data has been fully 
  ## handled. If an error occurs, the callback will be called with the error as its first argument.
  GC_ref(buf)
  write(S, buf.cstring, buf.len) do (err: ref NodeError):
    GC_unref(buf)
    if cb != nil:
      cb(err)

proc writeCork*(S: NodeStream) =
  ## Forces buffering of all writes.
  ## 
  ## Buffered data will be flushed either at ``writeUncork()`` or at ``writeEnd()`` call.
  ## If called n-times for the same ``S``, n calls to ``writeUncork()`` are needed to uncork ``S``. 
  inc(S.writeCorks)

proc writeUncork*(S: NodeStream) = 
  ## Flush all data, buffered since ``writeCork()`` call.
  if S.writeCorks > 0:
    dec(S.writeCorks)
    if statClosed     notin S.stats and 
       statWriteEnded notin S.stats and 
       statWriteReady in    S.stats and 
       statWriting    notin S.stats and
       S.writeCorks <= 0 and 
       S.writeBufLen > 0:
      let err = doClearBuf(S)
      if err < 0:
        S.error = newNodeError(err)
        close(S)
      else:
        incl(S.stats, statWriting)

proc allocCb(handle: ptr Handle, size: csize, buf: ptr Buffer) {.cdecl.} =
  let S = cast[NodeStream](handle.data)
  if statFlowing in S.stats:
    buf.base = S.readBuf[0].addr
    buf.length = BufSize
  else:
    buf.base = offsetChar(S.readBuf[0].addr, S.readBufLen) 
    buf.length = BufSize - S.readBufLen

proc readOnEnd(S: NodeStream) =
  incl(S.stats, statReadEnded)
  if statFlowing in S.stats:
    incl(S.stats, statReadEndEmitted)
    if S.readEndCb != nil:
      S.readEndCb()
    if statWriteEndEmitted in S.stats:
      close(S)

proc readOnData(S: NodeStream, size: int) =
  if statFlowing in S.stats:
    if S.readCb != nil:
      S.readCb(addr(S.readBuf[0]), size)
  else:
    inc(S.readBufLen, size)
    if S.readBufLen >= BufSize:
      let err = readStop(cast[ptr Stream](addr(S.handle)))
      if err < 0:
        S.error = newNodeError(err)
        close(S)
      else:
        excl(S.stats, statReading) 

proc readCb(handle: ptr Stream, nread: cssize, buf: ptr Buffer) {.cdecl.} =
  if nread == 0: # EINTR or EAGAIN or EWOULDBLOCK
    return
  let S = cast[NodeStream](handle.data)
  if nread < 0:
    if cint(nread) == uv.EOF:
      readOnEnd(S)
    else:
      S.error = newNodeError(cint(nread))
      close(S)
  else:
    readOnData(S, int(cint(nread)))

proc readResume*(S: NodeStream) =
  ## Switchs ``S`` into flowing mode, data is read from the underlying 
  ## system and provided to your program as fast as possible. 
  if statFlowing notin S.stats:
    incl(S.stats, statFlowing)
    if statClosed        notin S.stats and 
       statWaitingClosed notin S.stats:
      if statReadEnded in S.stats:
        if statReadEndEmitted notin S.stats:
          incl(S.stats, statReadEndEmitted)
          if S.readEndCb != nil:
            S.readEndCb()
          if statWriteEndEmitted in S.stats:
            close(S)
      else:
        if statReading notin S.stats:
          let err = readStart(cast[ptr Stream](addr(S.handle)), allocCb, readCb)
          if err < 0:
            S.error = newNodeError(err)
            close(S)
          else:
            incl(S.stats, statReading)
            if S.readBufLen > 0:
              assert S.readBufLen == BufSize
              if S.readCb != nil:
                S.readCb(addr(S.readBuf[0]), S.readBufLen)
              S.readBufLen = 0  

proc readPause*(S: NodeStream) =
  ## Switchs ``S`` into paused mode, any data that becomes available
  ## will remain in the internal buffer.
  excl(S.stats, statFlowing)

proc isFlowing*(S: NodeStream): bool =
  ## Checks whether or not the stream ``S`` is in flowing mod.
  result = statFlowing in S.stats

proc isNeedDrain*(S: NodeStream): bool =
  ## When writes to ``S``, the data may be buffered internally, so it is best not to write
  ## excessively. If the buffered memory overflow the inner boundary, this proc returns ``true``.
  result = statWriteNeedDrain in S.stats

proc isFailed*(S: NodeStream): bool = 
  ## Checks if ``S`` has an internal error.
  result = S.error != nil

type
  TcpStream* = ref object of NodeStream ## Abstraction of TCP communication based on stream IO manner. 
    connectCb: proc () {.closure, gcsafe.}
    domain: Domain

proc newTcpStream(): TcpStream =
  ## Create a new TCP connection.
  new(result)
  GC_ref(result) 
  result.writeBuf = @[]
  result.stats = {}
  let err = init(getDefaultLoop(), cast[ptr Tcp](addr(result.handle)))
  if err < 0:
    result.error = newNodeError(err)
    close(result)  
  else:
    result.handle.data = cast[pointer](result)

proc `onConnect=`*(S: TcpStream, cb: proc () {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when connecting successfuly. 
  S.connectCb = cb

proc toIp4Name(sa: ptr SockAddrIn): string = 
  result = newString(16) # 3 * 4 + 3
  let err = toIp4Name(sa, result, 16)
  if err < 0:
    raise newNodeError(err)
  setLen(result, result.cstring.len)

proc toIp6Name(sa: ptr SockAddrIn6): string = 
  result = newString(40) # 4 * 8 + 7
  let err = toIp6Name(sa, result, 40)
  if err < 0:
    raise newNodeError(err)
  setLen(result, result.cstring.len)

proc getLocalAddr*(S: TcpStream): 
    tuple[domain: Domain, address: string, port: Port] = 
  ## Get the local address infomation.   
  case S.domain
  of Domain.AF_INET:
    var sa: SockAddrIn
    var saLen = sizeof(SockAddrIn).cint
    let err = getSockName(cast[ptr Tcp](S.handle.addr), cast[ptr SockAddr](sa.addr), saLen)
    if err < 0:
      raise newNodeError(err)
    result.address = toIp4Name(sa.addr)
    result.domain = Domain.AF_INET
    result.port = Port(nativesockets.ntohs((sa.sin_port)))
  of Domain.AF_INET6:
    var sa: SockAddrIn6
    var saLen = sizeof(SockAddrIn6).cint
    let err = getSockName(cast[ptr Tcp](S.handle.addr), cast[ptr SockAddr](sa.addr), saLen)
    if err < 0:
      raise newNodeError(err)
    result.address = toIp6Name(sa.addr)
    result.domain = Domain.AF_INET
    result.port = Port(nativesockets.ntohs((sa.sin6_port)))
  else:
    raise newNodeError(uv.EAI_ADDRFAMILY)

proc getPeerAddr*(S: TcpStream): 
    tuple[domain: Domain, address: string, port: Port] = 
  ## Get the peer address infomation.   
  case S.domain
  of Domain.AF_INET:
    var sa: SockAddrIn
    var saLen = sizeof(SockAddrIn).cint
    let err = getPeerName(cast[ptr Tcp](S.handle.addr), cast[ptr SockAddr](sa.addr), saLen)
    if err < 0:
      raise newNodeError(err)
    result.address = toIp4Name(sa.addr)
    result.domain = Domain.AF_INET
    result.port = Port(nativesockets.ntohs((sa.sin_port)))
  of Domain.AF_INET6:
    var sa: SockAddrIn6
    var saLen = sizeof(SockAddrIn6).cint
    let err = getPeerName(cast[ptr Tcp](S.handle.addr), cast[ptr SockAddr](sa.addr), saLen)
    if err < 0:
      raise newNodeError(err)
    result.address = toIp6Name(sa.addr)
    result.domain = Domain.AF_INET
    result.port = Port(nativesockets.ntohs((sa.sin6_port)))
  else:
    raise newNodeError(uv.EAI_ADDRFAMILY)

proc setNoDelay*(S: TcpStream, enable: bool) =
  ## Disables the Nagle algorithm. By default TCP connections use the 
  ## Nagle algorithm, they buffer data before sending it off.
  let err = setNoDelay(cast[ptr Tcp](S.handle.addr), if enable: 1 else: 0)
  if err < 0:
    raise newNodeError(err)

proc setKeepAlive*(S: TcpStream, enable: bool, delay: cuint) =
  ## Enable / disable TCP keep-alive. delay is the initial delay in seconds, ignored when 
  ## enable is ``false``.
  let err = setKeepAlive(cast[ptr Tcp](S.handle.addr), if enable: 1 else: 0, delay)
  if err < 0:
    raise newNodeError(err)

proc connectCb(req: ptr Connect, status: cint) {.cdecl.} =
  let S = cast[TcpStream](req.data)
  dealloc(req)
  if status < 0:
    S.error = newNodeError(status)
    close(S)
  else:
    incl(S.stats, statWriteReady)
    if S.connectCb != nil:
      S.connectCb()

proc connect*(port: Port, address = "127.0.0.1", domain = Domain.AF_INET): TcpStream =
  ## Establishs an IPv4 or IPv6 TCP connection and returns a fresh ``TcpStream``.
  template condFree(exp: untyped): untyped =
    let err = exp
    if err < 0:
      uv.freeAddrInfo(reqGetAI.addrInfo)
      dealloc(reqConn)
      result.error = newNodeError(err)
      close(result)
      return
  result = newTcpStream()
  result.domain = domain
  if not result.isFailed:
    var reqConn = cast[ptr Connect](alloc0(sizeof(Connect)))
    var reqGetAI: GetAddrInfo
    var ai: uv.AddrInfo
    ai.ai_family = toInt(domain)
    ai.ai_socktype = 0
    ai.ai_protocol = 0
    condFree getAddrInfo(getDefaultLoop(), addr(reqGetAI), nil, 
                         address, $(int(port)), addr(ai))
    reqConn.data = cast[pointer](result)
    condFree connect(reqConn, cast[ptr Tcp](addr(result.handle)),
                     reqGetAI.addrInfo.ai_addr, connectCb)
    uv.freeAddrInfo(reqGetAI.addrInfo) 
    readResume(result) 

proc accept*(server: ptr Tcp, domain = Domain.AF_INET, 
             closeHandCb: proc (err: ref NodeError) {.closure, gcsafe.} = nil): TcpStream = 
  ## Accept incoming connections, returns a new ``TcpStream`` which is a wrapper of a connection.
  result = newTcpStream()
  result.domain = domain
  result.closeHandCb = closeHandCb
  if not result.isFailed:
    let err = accept(cast[ptr Stream](server), cast[ptr Stream](addr(result.handle)))
    if err < 0:
      result.error = newNodeError(err)
      close(result)
    else:
      incl(result.stats, statWriteReady)
      readResume(result) 






