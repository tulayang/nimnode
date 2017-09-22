#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, node, nativesockets, strtabs

proc consServer() =
  var server = newHttpServer(1_024_000)
  serve(server, Port(10000))
  server.onRequest = proc (stream: HttpStream) =
    stream.writeCork()
    stream.writeHead(200, newStringTable({
      "Content-Length": "11"
    }))
    stream.write("hello world")
    stream.writeUncork()

consServer()
runLoop()