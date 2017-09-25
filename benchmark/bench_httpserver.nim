#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, node, nativesockets, strtabs

proc consServer() =
  var server = newHttpServer(1_024_000)
  serve(server, Port(10000))
  server.onRequest = proc (stream: HttpServerStream) =
    # stream.writeCork()
    # stream.writeHead(200, newStringTable({
    #   "Transfer-Encoding": "chunked"
    # }))
    # stream.writeChunk("hello world")
    # stream.writeChunkTail()
    # stream.writeChunk(200, newStringTable({
    #   "Transfer-Encoding": "chunked"
    # }), "hello world")
    # stream.writeChunkTail()
    # stream.writeUncork()
    var buf = initResponseBuffer(32)  
    writeHead(buf, 200, {
      "Transfer-Encoding": "chunked"
    })
    writeChunk(buf, "hello world")
    writeChunkTail(buf)
    write(stream, buf)

consServer()
runLoop()