import unittest, uv.error, uv.loop, uv.handle, uv.signal
from posix import SIGINT

suite "uv.signal":
  var signal: Signal
  let signalPtr = addr(signal)

  test "init":
    check init(getDefaultLoop(), signalPtr) == 0
    check signal.typ == hdlSignal
  
  test "start stop":
    proc cb(handle: ptr Signal, signum: cint) {.cdecl.} =
      if signum == SIGINT:
        echo "  Signal got SIGINT ."
      else:
        echo "  Signal got ERROR ."
      check stop(handle) == 0
    check start(signalPtr, cb, SIGINT) == 0
    check run(getDefaultLoop(), runDefault) == 0
