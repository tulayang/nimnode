import unittest, uv.error, uv.loop
from posix import SIGPROF, SIGSYS

suite "uv.loop":
  var loop: Loop

  test "init":
    check init(addr(loop)) == 0

  test "configure":
    check configure(addr(loop), optBlockSignal, SIGSYS) == EINVAL
    check configure(addr(loop), optBlockSignal, SIGPROF) == 0

  test "close":
    check close(addr(loop)) == 0

  test "getDefaultLoop":
    check getDefaultLoop() != nil
    check getDefaultLoop() == getDefaultLoop()

  test "run":
    check run(getDefaultLoop(), runDefault) == 0

  test "isAlive":
    check isAlive(getDefaultLoop()) == 0

  test "stop":
    stop(getDefaultLoop())

  test "sizeofLoop":
    echo "  Size of the Loop structure: ",  sizeofLoop(), " bytes"

  test "getBackendFd":
    echo "  Backend file descriptor: ", getBackendFd(getDefaultLoop())

  test "getBackendTimeout":
    echo "  Poll timeout: ", getBackendTimeout(getDefaultLoop())

  test "now":
    echo "  now: ", now(getDefaultLoop())

  test "updateTime":
    updateTime(getDefaultLoop())
    echo "  now: ", now(getDefaultLoop())
