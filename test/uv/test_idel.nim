import unittest, uv.error, uv.loop, uv.handle, uv.timer, uv.idle

suite "uv.idle":
  var idle: Idle
  let idlePtr = addr(idle)
  var timer: Timer
  let timerPtr = addr(timer)

  test "init":
    check init(getDefaultLoop(), timerPtr) == 0
    check init(getDefaultLoop(), idlePtr) == 0
    check idle.typ == hdlidle
  
  test "start stop":
    var i = 0
    proc timerCb(handle: ptr Timer) {.cdecl.} =
      echo "  Timer got ."
      inc(i)
      if i >= 2:
        check stop(handle) == 0
    check start(timerPtr, timerCb, uint64(1000), uint64(1000)) == 0
    proc idleCb(handle: ptr Idle) {.cdecl.} =
      echo "  idle got ."
      if i >= 1:
        check stop(handle) == 0
    check start(idlePtr, idleCb) == 0
    check run(getDefaultLoop(), runDefault) == 0
