#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import uv, error, streams, net, nativesockets, httpkit

type
  HttpStream* = ref object
    base: TcpStream
    parser: RequestParser
    error: ref NodeError
    readCb: proc (data: pointer, size: int) {.closure, gcsafe.}
    readEndCb: proc () {.closure, gcsafe.}
    writeDrainCb: proc () {.closure, gcsafe.}
    writeEndCb: proc () {.closure, gcsafe.}
    closeCb: proc (err: ref NodeError) {.closure, gcsafe.}

  HttpServer* = ref object 
    base: TcpServer
    requestCb: proc (stream: HttpStream) {.closure, gcsafe.}
    closeCb: proc (err: ref NodeError) {.closure, gcsafe.}


template offsetChar(x: pointer, i: int): pointer =
  cast[pointer](cast[ByteAddress](x) + i * sizeof(char))

proc close*(H: HttpStream) =
  close(H.base)

proc closeSoon*(H: HttpStream) =
  closeSoon(H.base)

proc newHttpStream(T: TcpStream): HttpStream =
  new(result)

proc close*(server: HttpServer) = 
  close(server.base)

proc newHttpServer*(maxConnections = 1024): HttpServer =
  new(result)
  let S = result
  S.base = newTcpServer(maxConnections)

  S.base.onClose = proc (err: ref NodeError) = 
    S.closeCb(err) # 错误主要来自 Tcp

  S.base.onConnection = proc (T: TcpStream) = 
    let H = newHttpStream(T)
    T.onRead = proc (data: pointer, size: int) = 
      for state in H.parser.parse(data, size):
        case state
        of statReqHead:
          echo getHead(H.parser)
          S.requestCb(H) # TODO +请求头
        of statReqData:
          let (offset, size) = H.parser.getData()
          H.readCb(offsetChar(data, offset), size)
        of statReqDataChunked:
          discard # H.readChunked() 表示读取完毕一块 chunked 数据，对于 docker 以 JSON 作为 chunked 数据很有用
        of statReqDataEnd:
          H.readEndCb()
          # keep-alive ?
        of statReqExpect100Continue:
          discard # write(T, "HTTP/1.1 100 Continue\c\L\c\L")
                  # TODO 更多研究
        of statReqExceptOther:
          discard # write(T, "HTTP/1.1 417 Expectation Failed\c\L\c\L") 
                  # TODO 更多研究
        of statReqUpgrade:
          discard # TODO 更多研究 
        of statReqError:
          H.error = newNodeError(UNKNOWNSYS) # TODO 更详细的错误
          readPause(T)
          closeSoon(T) # TODO 发送错误消息

    T.onReadEnd = proc () = 
      # 如果正在解析 ... ，那么这应该是一个错误
      # 否则，则为正确关闭
      # TODO
      closeSoon(T) # TODO 发送错误消息

    T.onWriteDrain = proc () =
      H.writeDrainCb()

    # T.onWriteEnd = proc () =

    T.onClose = proc (err: ref NodeError) = 
      H.closeCb(if H.error != nil: H.error else: err) # TODO 报告错误消息 

proc serve*(server: HttpServer, port: Port, address = "127.0.0.1",
            domain = Domain.AF_INET, backlog = SOMAXCONN) =
  ## Start the process of listening for incoming HTTP connections on the specified 
  ## ``address`` and ``port``. 
  ##
  ## ``backlog`` specifies the length of the queue for pending connections. When the 
  ## queue fills, new clients attempting to connect fail with ECONNREFUSED until the 
  ## server calls accept to accept a connection from the queue.
  serve(server.base, port, address, domain, backlog)
  
    









