import unittest, uv.error, uv.loop, uv.handle, uv.stream, uv.pipe, uv.misc, uv.process

suite "uv.process": 
  var child = cast[ptr Process](alloc0(sizeof(Process)))
  var options = cast[ptr ProcessOptions](alloc0(sizeof(ProcessOptions)))
  var stdio = cast[ptr array[3, StdioContainer]](alloc0(3 * sizeof(StdioContainer))) 

  test "spawn":
    options.exitCb = proc(handle: ptr Process, exitCode: int64, signal: cint) {.cdecl.} =
      echo "  Exit proc, pid ", $handle.pid & " exitCode " & $exitCode, " signal " & $signal & " ."
    options.file = "/usr/bin/nim"
    options.args = allocCStringArray(["/usr/bin/nim", "--version"])
    options.flags = cuint(prcDetached)
    options.stdioCount = 3
    stdio[0].flags = cuint(stdioIgnore)
    stdio[1].flags = cuint(stdioInheritFd)
    stdio[1].data.fd = 1
    stdio[2].flags = cuint(stdioCreatePipe) or cuint(stdioReadablePipe)
    var pipe = cast[ptr Pipe](alloc0(sizeof(Pipe)))
    check init(getDefaultLoop(), pipe, 1) == 0
    #stream2.typ = hdlNamedPipe
    stdio[2].data.stream = cast[ptr Stream](pipe)
    options.stdio = addr(stdio[0])
    check spawn(getDefaultLoop(), child, options) == 0

    proc allocCb(handle: ptr Handle, size: csize, buf: ptr Buffer) {.cdecl.} =
      echo "alloc ..."
      buf.base = cast[cstring](alloc0(size))
      buf.length = size

    proc readCb(handle: ptr Stream, nread: cssize, buf: ptr Buffer) {.cdecl.} = 
      if nread < 0:
        if nread == cssize(EOF):
          echo "  finished ."
        else:
          raise newException(IOError, "read error")
      else:
        echo "  buf: ", buf.base, " length: ", $buf.length

    check readStart(stdio[2].data.stream, allocCb, readCb) == 0
    check run(getDefaultLoop(), runDefault) == 0

  dealloc(child)
  dealloc(options)
  dealloc(stdio)