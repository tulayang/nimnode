import unittest, uv.error, uv.loop, uv.handle, uv.timer

suite "uv.timer":
  var timer: Timer
  let timerPtr = addr(timer)

  test "init":
    check init(getDefaultLoop(), timerPtr) == 0
    check timer.typ == hdlTimer
  
  test "start stop":
    var i = 0
    proc cb(handle: ptr Timer) {.cdecl.} =
      echo "  timer got ."
      inc(i)
      if i >= 2:
        check stop(handle) == 0
    check start(timerPtr, cb, uint64(1000), uint64(1000)) == 0
    check run(getDefaultLoop(), runDefault) == 0

  test "setRepeat getRepeat":
    var i = 0
    proc cb(handle: ptr Timer) {.cdecl.} =
      echo "  timer got ."
      inc(i)
      if i >= 2:
        check stop(handle) == 0
    check start(timerPtr, cb, uint64(1000), uint64(1000)) == 0
    setRepeat(timerPtr, uint64(100))
    check getRepeat(timerPtr) == uint64(100)
    check run(getDefaultLoop(), runDefault) == 0