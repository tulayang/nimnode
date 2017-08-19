
import node.uv.error, node.uv.loop, node.uv.handle 
import node.uv.stream, node.uv.tcp, node.uv.misc


proc cond(x: cint) =
  if x < 0:
    raise newException(OSError, $errName(x) & ":" & $strError(x))

var server = cast[ptr TCP](alloc0(sizeof(TCP)))
cond init(getDefaultLoop(), server)

var sockAddr: SockAddrIn
cond toIp4Addr("0.0.0.0", cint(10001), sockAddr)
cond bindAddr(server, cast[ptr SockAddr](addr(sockAddr)), cuint(0))

proc onAlloc(client: ptr Handle, size: csize, buf: ptr Buffer) {.cdecl.} =
  echo "  Alloc ."
  buf.base = cast[cstring](client.data)
  buf.length = 4096

proc onRead(client: ptr Stream, nread: cssize, buf: ptr Buffer) {.cdecl.} = 
  if nread == 0:
    echo "  EAGAIN or EWOULDBLOCK"
  elif nread < 0:
    if nread == cssize(EOF):
      echo "  Finished, close this client ."
      close(cast[ptr Handle](client), proc (client: ptr Handle) {.cdecl.} =
        dealloc(client)
        dealloc(client.data))
    else:
      echo "  Error read, close this client ."
      close(cast[ptr Handle](client), proc (client: ptr Handle) {.cdecl.} =
        dealloc(client)
        dealloc(client.data))
  else:
    echo "  Read buf: ", repr buf.base, " length: ", $buf.length

proc onConnection(server: ptr Stream, status: cint) {.cdecl.} =
  var client = cast[ptr TCP](alloc0(sizeof(TCP)))
  cond init(getDefaultLoop(), client)
  client.data = cast[cstring](alloc0(4096))

  cond accept(cast[ptr Stream](server), cast[ptr Stream](client))
  cond readStart(cast[ptr Stream](client), onAlloc, onRead)

cond listen(cast[ptr Stream](server), cint(511), onConnection)
cond run(getDefaultLoop(), runDefault)