import unittest, uv.error, uv.loop, uv.handle, uv.timer, uv.check

suite "uv.check":
  var check: Check
  let checkPtr = addr(check)
  var timer: Timer
  let timerPtr = addr(timer)

  test "init":
    check init(getDefaultLoop(), timerPtr) == 0
    check init(getDefaultLoop(), checkPtr) == 0
    check check.typ == hdlCheck
  
  test "start stop":
    var i = 0
    proc timerCb(handle: ptr Timer) {.cdecl.} =
      echo "  Timer got ."
      inc(i)
      if i >= 2:
        check stop(handle) == 0
    check start(timerPtr, timerCb, uint64(1000), uint64(1000)) == 0
    proc checkCb(handle: ptr Check) {.cdecl.} =
      echo "  Check got ."
      check stop(handle) == 0
    check start(checkPtr, checkCb) == 0
    check run(getDefaultLoop(), runDefault) == 0
