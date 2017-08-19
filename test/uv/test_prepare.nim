import unittest, uv.error, uv.loop, uv.handle, uv.prepare

suite "uv.prepare":
  var prepare: Prepare
  let preparePtr = addr(prepare)

  test "init":
    check init(getDefaultLoop(), preparePtr) == 0
    check prepare.typ == hdlPrepare
  
  test "start stop":
    var i = 0
    proc cb(handle: ptr Prepare) {.cdecl.} =
      echo "  Prepare got ."
      check stop(handle) == 0
    check start(preparePtr, cb) == 0
    check run(getDefaultLoop(), runDefault) == 0
