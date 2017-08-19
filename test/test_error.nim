#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, node, node.uv

suite "raise NodeError":
  test "common libuv errorno":
    try:
      raise newNodeError(uv.E2BIG)
    except:
      let e = (ref NodeError)(getCurrentException())
      check:
        e.errorCode == node.E2BIG
        e.msg == strError(uv.E2BIG)
    try:
      raise newNodeError(uv.EPROTONOSUPPORT)
    except NodeError:
      let e = (ref NodeError)(getCurrentException())
      check:
        e.errorCode == node.EPROTONOSUPPORT
        e.msg == strError(uv.EPROTONOSUPPORT)

  test "unknown errorno":    
    try:
      raise newNodeError(cint(-10000))
    except:
      let e = (ref NodeError)(getCurrentException())
      check:
        e.errorCode == node.UNKNOWNSYS
        e.msg == "unknown system error -10000"


