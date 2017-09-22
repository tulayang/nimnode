#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

# 和 nodejs 不同，nimnode 的 http 不要过多参与逻辑规则的制定，只要做一个底层 net
# 的 wrapper，解码，编码，io 由 net 处理；也不缓存请求头、响应头
#
# 是否应该把请求和响应的解析器合并为一个？
# ....................
#
# net 依赖标准库的 nativesockets，也只依赖 nativesockets
#
# 请求头、响应头应该怎么存储？ 每一次 request 都会刷新重置它们！所以，好的简单的处理方式是
# 和 HttpServerStream 绑定？

import uv, error, streams, net, nativesockets, httpkit, strtabs

type
  HttpServerStream* = ref object ##　服务端的 Http 流，每当有一个新的连接时，就同时在内部创建一个 Http 流
    base: TcpStream
    parser: RequestParser
    error: ref NodeError
    readCb: proc (data: pointer, size: int) {.closure, gcsafe.}
    readEndCb: proc () {.closure, gcsafe.}
    writeDrainCb: proc () {.closure, gcsafe.}
    writeEndCb: proc () {.closure, gcsafe.} ## 当关闭 outgoing，底层所有的数据发送完毕时触发
    ## 和 nodejs 不同，nimnode 提供灵活，而不过多的参与逻辑规则 
    closeCb: proc (err: ref NodeError) {.closure, gcsafe.}
    parsing: bool

  HttpServer* = ref object ## HTTP s object.
    base: TcpServer
    requestCb: proc (stream: HttpServerStream) {.closure, gcsafe.}
    closeCb: proc (err: ref NodeError) {.closure, gcsafe.}

template offsetChar(x: pointer, i: int): pointer =
  cast[pointer](cast[ByteAddress](x) + i * sizeof(char))

proc `onRead=`*(h: HttpServerStream, cb: proc (data: pointer, size: int) {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when reading a chunk of data.
  h.readCb = cb

proc `onReadEnd=`*(h: HttpServerStream, cb: proc () {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when reading the end of file.
  h.readEndCb = cb

proc `onWriteDrain=`*(h: HttpServerStream, cb: proc () {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when writing buffers is become empty from large than ``WriteOverLevel``.
  h.writeDrainCb = cb

proc `onWriteEnd=`*(h: HttpServerStream, cb: proc () {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when the write side is shutdowned.
  h.writeEndCb = cb

proc `onClose=`*(h: HttpServerStream, cb: proc (err: ref NodeError) {.closure, gcsafe.}) =
  ## Sets the callback which will be invoked when the stream is closed. If an error occurs, the callback will
  ##  be called with the error as its first argument.
  h.closeCb = cb

proc newHttpServerStream(t: TcpStream, lineLimit = 1024, headerLimit = 1024): HttpServerStream =
  new(result)
  result.base = t
  result.parser = initRequestParser(lineLimit, headerLimit)
  result.parsing = false

proc close*(h: HttpServerStream) =
  ## Close stream ``h``. Handles that wrap file descriptors are closed immediately.
  close(h.base)

proc closeSoon*(h: HttpServerStream) =
  ## Shutdown the outgoing (write) side and waits for all pending write requests to complete.
  ## After that, close the stream.
  closeSoon(h.base)

proc writeEnd*(h: HttpServerStream) =
  # Shutdown the outgoing (write) side and waits for all pending write requests to complete.
  writeEnd(h.base)

proc writeHead*(h: HttpServerStream, statusCode: int, 
                cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  let s = "HTTP/1.1 " & $statusCode & " OK\r\LContent-Length: 0\r\L\r\L"
  write(h.base, s, cb)

proc writeHead*(h: HttpServerStream, statusCode: int, headers: StringTableRef,
                cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  var s = "HTTP/1.1 " & $statusCode & " OK\r\L"
  for key,value in pairs(headers):
    add(s, key & ": " & value & "\r\L")
  add(s, "\r\L")
  write(h.base, s, cb)

proc write*(h: HttpServerStream, buf: pointer, size: int, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  write(h.base, buf, size, cb)

proc write*(h: HttpServerStream, buf: string, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =
  write(h.base, buf, cb)

proc writeCork*(h: HttpServerStream) =
  writeCork(h.base)

proc writeUncork*(h: HttpServerStream) =
  writeUncork(h.base)

proc readResume*(h: HttpServerStream) =
  readResume(h.base)

proc readPause*(h: HttpServerStream) =
  readPause(h.base)

proc isFlowing*(h: HttpServerStream): bool =
  isFlowing(h.base)

proc isNeedDrain*(h: HttpServerStream): bool =
  isNeedDrain(h.base)

proc request*(h: HttpServerStream): tuple[
  reqMethod: string, 
  url: string,
  protocol: tuple[orig: string, major, minor: int], 
  headers: StringTableRef
] =
  # TODO 优化，深 copy 转为浅 copy
  getHead(h.parser)

# TODO chunked string

proc `onRequest=`*(s: HttpServer, cb: proc (stream: HttpServerStream) {.closure, gcsafe.}) =
  s.requestCb = cb

proc `onClose=`*(s: HttpServer, cb: proc (err: ref NodeError) {.closure, gcsafe.}) =
  s.closeCb = cb

proc newHttpServer*(maxConnections = 1024, lineLimit = 1024, headerLimit = 1024): HttpServer =
  ## Creates a new Http Server.
  new(result)
  let s = result
  s.base = newTcpServer(maxConnections)

  s.base.onClose = proc (err: ref NodeError) = 
    s.closeCb(err) # 错误主要来自 Tcp

  s.base.onConnection = proc (t: TcpStream) = 
    let h = newHttpServerStream(t, lineLimit, headerLimit)
    t.onRead = proc (data: pointer, size: int) = 
      for state in h.parser.parse(data, size):
        case state
        of statReqError:
          h.error = newNodeError(END_BADREQ) 
          write(t, "HTTP/1.1 400 Bad Request\c\L\c\L") 
          readPause(t)
          closeSoon(t)
        of statReqExpect100Continue:
          parsing = false
          write(t, "HTTP/1.1 100 Continue\c\L\c\L")
          # 客户端发送 100 Continue 的请求不能包含请求体，否则，
          # 服务器仍然解析请求体，但是会引发逻辑错误
        of statReqExceptOther:
          write(t, "HTTP/1.1 417 Expectation Failed\c\L\c\L") 
          readPause(t)
          closeSoon(t)
        of statReqUpgrade:
          discard # TODO 更多研究
          # 我想让 Http Server 和 Http Upgrade Server 独立，
          # 处理 Upgrade 的 Http Server 不接受其他请求，这样可以使得服务器的模型更简单
          # 以下是 Upgrade 的处理： 
          #    删除所有 TcpStream 的挂载回调函数，由用户来控制转变为完全的 socket 通信
          # if h.upgradeCb != nil:
          #   t.onRead = nil
          #   t.onReadEnd = nil
          #   t.onWriteDrain = nil
          #   t.onWriteEnd = nil
          #   t.onClose = nil
          #   let (offset, size) = getRemainPacket(h.parser)
          #   h.upgradeCb(t, offsetChar(data, offset), size)
        of statReqHead:
          if s.requestCb != nil:
            s.requestCb(h) 
        of statReqData:
          if h.readCb != nil:
            let (offset, size) = getData(h.parser)
            h.readCb(offsetChar(data, offset), size)
        of statReqDataChunked:
          discard # h.readChunked() 表示读取完毕一块 chunked 数据，对于 docker 以 JSON 作为 chunked 数据很有用
        of statReqDataEnd:
          parsing = false
          if h.readEndCb != nil:
            h.readEndCb()
          # keep-alive ?

    t.onReadEnd = proc () = 
      # 如果正在解析 ... ，那么这应该是一个错误
      # 否则，则为正确关闭
      if h.parsing:
        write(t, "HTTP/1.1 400 Bad Request\c\L\c\L") 
      closeSoon(t) 

    t.onWriteDrain = proc () =
      if h.writeDrainCb != nil:
        h.writeDrainCb()

    t.onWriteEnd = proc () =
      if h.writeEndCb != nil:
        h.writeEndCb()

    t.onClose = proc (err: ref NodeError) = 
      if h.closeCb != nil:
        h.closeCb(if h.error != nil: h.error else: err) 
      # HTTP 服务器，我想让其安全运行，即便用户没有提供错误检查函数
      # elif h.error != nil:
      #   raise h.error
      # elif err != nil:
      #   raise err

proc close*(s: HttpServer) = 
  ## Close `server` to close the file descriptors and release internal resources. 
  close(s.base)

proc serve*(s: HttpServer, port: Port, address = "127.0.0.1",
            domain = Domain.AF_INET, backlog = SOMAXCONN) =
  ## Start the process of listening for incoming HTTP connections on the specified 
  ## ``address`` and ``port``. 
  ##
  ## ``backlog`` specifies the length of the queue for pending connections. When the 
  ## queue fills, new clients attempting to connect fail with ECONNREFUSED until the 
  ## s calls accept to accept a connection from the queue.
  serve(s.base, port, address, domain, backlog)
  
    









