#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, node, nativesockets

suite "TCP Server and Client":
  test "closeSoon to close read and write; close auto when writeEnded and readEnded":
    proc consServer() =
      var server = newTcpServer()
      var coin = 0
      server.serve(Port(10000), "127.0.0.1", domain=AF_INET)
      server.onConnection = proc (stream: TcpStream) =
        var message = ""
  
        stream.onRead = proc (data: pointer, size: int) =
          var s = newString(size)
          copyMem(s.cstring, data, size)
          add(message, s)

        stream.onReadEnd = proc () =
          check coin == 0
          inc(coin)
          write(stream, "recved " & message)
          closeSoon(stream)

        stream.onWriteEnd = proc () =  
          check coin == 1
          inc(coin)

        stream.onClose = proc (err: ref NodeError) =
          check err == nil
          check coin == 2
          inc(coin)
          close(server)

      server.onClose = proc (err: ref NodeError) =
        if err != nil:
          echo "Server Error: ", err.msg
        check coin == 3
        echo "       >>> server closed, coin=", $coin

    proc consClient() =
      var stream = connect(Port(10000), "127.0.0.1", domain=AF_INET)
      var message = ""
      var coin = 0

      stream.onConnect = proc () =
        check coin == 0
        inc(coin)
        write(stream, "hello world")
        writeEnd(stream)

      stream.onRead = proc (data: pointer, size: int) =
        var s = newString(size)
        copyMem(s.cstring, data, size)
        add(message, s)

      stream.onReadEnd = proc () =
        check message == "recved hello world"
        check coin == 2
        inc(coin)

      stream.onWriteEnd = proc () =  
        check coin == 1
        inc(coin)

      stream.onClose = proc (err: ref NodeError) =
        if err != nil:
          echo "Client Error: ", err.msg
        check err == nil
        check coin == 3
        echo "       >>> client closed, coin=", $coin

    consServer()
    consClient()
    runLoop()

  test "queue for a lot of write requests":
    proc consServer() =
      var server = newTcpServer()
      var coin = 0
      server.serve(Port(10000), "localhost")
      server.onConnection = proc (stream: TcpStream) =
        var message = ""
  
        stream.onRead = proc (data: pointer, size: int) =
          var s = newString(size)
          copyMem(s.cstring, data, size)
          add(message, s)

        stream.onReadEnd = proc () =
          check coin == 0
          inc(coin)
          write(stream, "recved " & message)
          closeSoon(stream)

        stream.onWriteEnd = proc () =  
          check coin == 1
          inc(coin)

        stream.onClose = proc (err: ref NodeError) =
          check err == nil
          check coin == 2
          inc(coin)
          close(server)

      server.onClose = proc (err: ref NodeError) =
        check err == nil
        check coin == 3
        echo "       >>> server closed, coin=", $coin

    proc consClient() =
      var stream = connect(Port(10000), "localhost")
      var message = ""
      var coin = 0

      stream.onConnect = proc () =
        check coin == 0
        inc(coin)
        var buf = cast[cstring](alloc(3))
        buf[0] = 'a'
        buf[1] = 'b'
        buf[2] = 'c'
        write(stream, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "bc"
        buf[1] = 'e'                                               
        write(stream, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "ec"
        buf[1] = 'o'                                              # "ec" => "oc"
        write(stream, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "oc"
        writeEnd(stream)

      stream.onRead = proc (data: pointer, size: int) =
        var s = newString(size)
        copyMem(s.cstring, data, size)
        add(message, s)

      stream.onReadEnd = proc () =
        check message == "recved bcococ"
        check coin == 2
        inc(coin)
        closeSoon(stream)

      stream.onWriteEnd = proc () =  
        check coin == 1
        inc(coin)

      stream.onClose = proc (err: ref NodeError) =
        check err == nil
        check coin == 3
        echo "       >>> client closed, coin=", $coin

    consServer()
    consClient()
    runLoop()

  




