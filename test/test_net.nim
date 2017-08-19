#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, node

suite "TCP Server and Client":
  test "closeSoon to close read and write; close auto when writeEnded and readEnded":
    proc consServer() =
      var server = newTcpServer()
      var coin = 0
      server.serve(Port(10000), "localhost")
      server.onConnection = proc (sock: TcpSocket) =
        var message = ""
  
        sock.onData = proc (data: pointer, size: int) =
          var s = newString(size)
          copyMem(s.cstring, data, size)
          add(message, s)

        sock.onEnd = proc () =
          check coin == 0
          inc(coin)
          write(sock, "recved " & message)
          closeSoon(sock)

        sock.onFinish = proc () =  
          check coin == 1
          inc(coin)

        sock.onClose = proc (err: ref NodeError) =
          check err == nil
          check coin == 2
          inc(coin)
          close(server)

      server.onClose = proc (err: ref NodeError) =
        check coin == 3
        echo "       >>> server closed, coin=", $coin

    proc consClient() =
      var sock = connect(Port(10000), "localhost")
      var message = ""
      var coin = 0

      sock.onConnect = proc () =
        check coin == 0
        inc(coin)
        write(sock, "hello world")
        writeEnd(sock)

      sock.onData = proc (data: pointer, size: int) =
        var s = newString(size)
        copyMem(s.cstring, data, size)
        add(message, s)

      sock.onEnd = proc () =
        check message == "recved hello world"
        check coin == 2
        inc(coin)

      sock.onFinish = proc () =  
        check coin == 1
        inc(coin)

      sock.onClose = proc (err: ref NodeError) =
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
      server.onConnection = proc (sock: TcpSocket) =
        var message = ""
  
        sock.onData = proc (data: pointer, size: int) =
          var s = newString(size)
          copyMem(s.cstring, data, size)
          add(message, s)

        sock.onEnd = proc () =
          check coin == 0
          inc(coin)
          write(sock, "recved " & message)
          closeSoon(sock)

        sock.onFinish = proc () =  
          check coin == 1
          inc(coin)

        sock.onClose = proc (err: ref NodeError) =
          check err == nil
          check coin == 2
          inc(coin)
          close(server)

      server.onClose = proc (err: ref NodeError) =
        check err == nil
        check coin == 3
        echo "       >>> server closed, coin=", $coin

    proc consClient() =
      var sock = connect(Port(10000), "localhost")
      var message = ""
      var coin = 0

      sock.onConnect = proc () =
        check coin == 0
        inc(coin)
        var buf = cast[cstring](alloc(3))
        buf[0] = 'a'
        buf[1] = 'b'
        buf[2] = 'c'
        write(sock, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "bc"
        buf[1] = 'e'                                               
        write(sock, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "ec"
        buf[1] = 'o'                                              # "ec" => "oc"
        write(sock, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "oc"
        writeEnd(sock)

      sock.onData = proc (data: pointer, size: int) =
        var s = newString(size)
        copyMem(s.cstring, data, size)
        add(message, s)

      sock.onEnd = proc () =
        check message == "recved bcococ"
        check coin == 2
        inc(coin)
        closeSoon(sock)

      sock.onFinish = proc () =  
        check coin == 1
        inc(coin)

      sock.onClose = proc (err: ref NodeError) =
        check err == nil
        check coin == 3
        echo "       >>> client closed, coin=", $coin

    consServer()
    consClient()
    runLoop()

  test "write cork and uncork":
    proc consServer() =
      var server = newTcpServer()
      var coin = 0
      server.serve(Port(10000), "localhost")
      server.onConnection = proc (sock: TcpSocket) =
        var message = ""
  
        sock.onData = proc (data: pointer, size: int) =
          var s = newString(size)
          copyMem(s.cstring, data, size)
          add(message, s)
          if message.len == 6:
            write(sock, "recved " & message)
            writeEnd(sock)

        sock.onEnd = proc () =
          check coin == 1
          inc(coin)

        sock.onFinish = proc () =  
          check coin == 0
          inc(coin)

        sock.onClose = proc (err: ref NodeError) =
          if err != nil:
            echo err.msg
          check coin == 2
          inc(coin)
          close(server)

      server.onClose = proc (err: ref NodeError) =
        check coin == 3
        echo "       >>> server closed, coin=", $coin

    proc consClient() =
      var sock = connect(Port(10000), "localhost")
      var message = ""
      var coin = 0
      writeCork(sock)

      sock.onConnect = proc () =
        check coin == 0
        inc(coin)
        var buf = cast[cstring](alloc(3))
        buf[0] = 'a'
        buf[1] = 'b'
        buf[2] = 'c'
        write(sock, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "bc"
        buf[1] = 'e'                                              # "bc" => "ec" 
        write(sock, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "ec" 
        buf[1] = 'o'                                              # "ec" => "oc"
        write(sock, cast[pointer](cast[ByteAddress](buf) + 1), 2) # "oc" 
        writeUncork(sock)

      sock.onData = proc (data: pointer, size: int) =
        var s = newString(size)
        copyMem(s.cstring, data, size)
        add(message, s)

      sock.onEnd = proc () =
        check message == "recved ocococ"
        check coin == 1
        inc(coin)
        closeSoon(sock)

      sock.onFinish = proc () =  
        check coin == 2
        inc(coin)

      sock.onClose = proc (err: ref NodeError) =
        check coin == 3
        echo "       >>> client closed, coin=", $coin

    consServer()
    consClient()
    runLoop()





