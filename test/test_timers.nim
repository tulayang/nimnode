#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, node, os, asyncfutures

suite "Timer":
  test "setTimeout three times, coin should be 2":
    var coin = 0
    var timer = newTimer()
    setTimeout(timer, 10) do () {.gcsafe.}:
      check false
    setTimeout(timer, 100) do () {.gcsafe.}:
      check coin == 0
      inc(coin)
      setTimeout(timer, 100) do () {.gcsafe.}:
        check coin == 1
        inc(coin)
        setTimeout(timer, 10) do () {.gcsafe.}:
          check coin == 2
          echo "       >>> coin=", coin
    runLoop()

  test "sleep 10ms, coin should be 1":
    var coin = 0
    var timer1 = newTimer()
    setTimeout(timer1, 10) do () {.gcsafe.}:
      check coin == 0
      inc(coin)
    sleep(10)
    var timer2 = newTimer()
    setTimeout(timer2, 100) do () {.gcsafe.}:
      check coin == 1
      echo "       >>> coin=", coin
    runLoop() 

  test "setTimeout global, coin should be 1":
    var coin = 0
    setTimeout(100) do () {.gcsafe.}:
      check coin == 1
      echo "       >>> coin=", coin
      inc(coin)
    setTimeout(10) do () {.gcsafe.}:
      check coin == 0
      inc(coin)
    runLoop()

  test "clearTimeout, coin should be 1":
    var coin = 0
    var timer = setTimeout(100) do () {.gcsafe.}:
      check coin == 1
      inc(coin)
    setTimeout(10) do () {.gcsafe.}:
      check coin == 0
      inc(coin)
      clearTimeout(timer)
      setTimeout(10) do () {.gcsafe.}:
        check coin == 1
        echo "       >>> coin=", coin
    runLoop()
      
suite "Ticker":
  test "callNext three times, coin should be 2":
    var coin = 0
    callNext() do ():
      check coin == 0
      inc(coin)
      callNext() do ():
        check coin == 2
        echo "       >>> coin=", coin
    callNext() do ():
      check coin == 1
      inc(coin)  
    runLoop()
  
  test "callSoon three times, coin should be 2":
    var coin = 0
    callSoon() do ():
      check coin == 0
      inc(coin)
      callSoon() do ():
        check coin == 2
        echo "       >>> coin=", coin
    callSoon() do ():
      check coin == 1
      inc(coin)  
    runLoop()


