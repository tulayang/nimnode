#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## Provides an asynchronous network wrapper. It contains functions for creating 
## both servers and clients (called streams). 

import uv, error, streams, nettype

type
  TcpServer* = ref object ## Abstraction of TCP server.
    onConnection*: proc (sock: TcpSocket) {.closure, gcsafe.}
    onClose*: proc (err: ref NodeError) {.closure, gcsafe.}
    handle: Tcp
    maxConnections: int
    connections: int
    error: ref NodeError
    closed: bool

proc closeCb(handle: ptr Handle) {.cdecl.} =
  var server = cast[TcpServer](handle.data) 
  GC_unref(server)
  if server.onClose != nil:
    server.onClose(server.error)
  elif server.error != nil:
    raise server.error 

proc close*(server: TcpServer) =
  ## Close `server` to close the file descriptors and release internal resources. 
  if not server.closed:
    server.closed = true
    close(cast[ptr Handle](addr(server.handle)), closeCb)

proc newTcpServer*(maxConnections = 1024): TcpServer =
  ## Create a new TCP server.
  new(result)
  GC_ref(result)
  result.closed = false
  result.maxConnections = maxConnections
  let err = init(getDefaultLoop(), cast[ptr Tcp](addr(result.handle)))
  if err < 0:
    result.error = newNodeError(err)
    close(result)
  else:
    result.handle.data = cast[pointer](result)   

proc bindAddr(handle: ptr Tcp, port: Port, hostname = "127.0.0.1", domain = Domain.AF_INET): cint =
  template condFree(exp: cint): untyped =
    if exp < 0:
      uv.freeAddrInfo(req.addrInfo)
      return exp
  var req: GetAddrInfo
  var hints: uv.AddrInfo
  hints.ai_family = cint(domain)
  hints.ai_socktype = 0
  hints.ai_protocol = 0
  condFree getAddrInfo(getDefaultLoop(), addr(req), nil, hostname, $(int(port)), addr(hints))
  condFree bindAddr(handle, req.addrInfo.ai_addr, cuint(0))
  uv.freeAddrInfo(req.addrInfo)

proc connectionCb(handle: ptr Stream, status: cint) {.cdecl.} =
  let server = cast[TcpServer](handle.data)
  if status < 0 or server.connections >= server.maxConnections or server.onConnection == nil:
    discard
  else:
    var sock = accept(addr(server.handle)) do (err: ref NodeError):
      dec(server.connections)
    inc(server.connections)
    server.onConnection(sock)

proc serve*(server: TcpServer, port: Port, hostname = "127.0.0.1", backlog = 511, domain = Domain.AF_INET) =
  ## Start the process of listening for incoming TCP connections on the specified 
  ## ``hostname`` and ``port``. 
  ##
  ## ``backlog`` specifies the length of the queue for pending connections. When the 
  ## queue fills, new clients attempting to connect fail with ECONNREFUSED until the 
  ## server calls accept to accept a connection from the queue.
  template cond(exp: cint): untyped =
    let err = exp
    if err < 0:
      server.error = newNodeError(err)
      close(server)
      return
  cond bindAddr(addr(server.handle), port, hostname, domain)
  cond listen(cast[ptr Stream](addr(server.handle)), cint(backlog), connectionCb)
  



