import unittest, uv.version

suite "uv.version":
  test "version":
    echo "  Output: ", version()

  test "versionString":
    echo "  Output: ", versionString()

  test "VERSION_SUFFIX":
    echo "  Output: ", VERSION_SUFFIX
