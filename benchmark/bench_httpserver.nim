#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, node, nativesockets, strtabs

proc consServer() =
  var server = newHttpServer(1_024_000)
  var data = readFile("./benchmark/data")
  serve(server, Port(10000))
  server.onRequest = proc (stream: HttpServerStream) =
    var buf = initResponseBuffer(4096)  
    writeHead(buf, 200, {
      "Transfer-Encoding": "chunked"
    })
    writeChunk(buf, data)
    writeChunk(buf, data)
    writeChunkTail(buf)
    write(stream, buf)

consServer()
runLoop()