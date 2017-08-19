import unittest, uv.error

suite "uv.error":
  test "translateSysError":
    echo "  EHOSTDOWN code: ", translateSysError(EHOSTDOWN)

  test "strError":
    echo "  EHOSTDOWN msg: ", strError(EHOSTDOWN)

  test "errName":
    echo "  EHOSTDOWN name: ", errName(EHOSTDOWN)
