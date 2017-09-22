#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## Provides an asynchronous network wrapper. It contains functions for creating 
## both servers and clients (called streams). 

import uv, error, streams, nativesockets

type
  TcpServer* = ref object ## Abstraction of TCP server.
    connectionCb: proc (stream: TcpStream) {.closure, gcsafe.}
    closeCb: proc (err: ref NodeError) {.closure, gcsafe.}
    handle: Tcp
    maxConnections: int
    connections: int
    error: ref NodeError
    domain: Domain
    closed: bool

const InAddrAny* = "0.0.0.0"
const InAddr6Any* = "::"

proc `onConnection=`*(server: TcpServer, cb: proc (stream: TcpStream) {.closure, gcsafe.}) =
  server.connectionCb = cb

proc `onClose=`*(server: TcpServer, cb: proc (err: ref NodeError) {.closure, gcsafe.}) =
  server.closeCb = cb

proc closeCb(handle: ptr Handle) {.cdecl.} =
  var server = cast[TcpServer](handle.data) 
  GC_unref(server)
  if server.closeCb != nil:
    server.closeCb(server.error)
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

proc bindAddr(handle: ptr Tcp, port: Port, address: string, domain = Domain.AF_INET): cint =
  template condFree(exp: cint): untyped =
    if exp < 0:
      uv.freeAddrInfo(req.addrInfo)
      return exp
  var req: GetAddrInfo
  var ai: uv.AddrInfo
  ai.ai_family = toInt(domain)
  ai.ai_socktype = 0
  ai.ai_protocol = 0
  if address == "":
    var newAddress: string 
    case domain
    of AF_INET: 
      shallowCopy(newAddress, InAddrAny)
    of AF_INET6: 
      shallowCopy(newAddress, InAddr6Any)
    else:
      condFree uv.EAI_NODATA
    condFree getAddrInfo(getDefaultLoop(), addr(req), nil, newAddress, $(int(port)), addr(ai))
  else:
    condFree getAddrInfo(getDefaultLoop(), addr(req), nil, address, $(int(port)), addr(ai))
  condFree bindAddr(handle, req.addrInfo.ai_addr, cuint(0))
  uv.freeAddrInfo(req.addrInfo)

proc connectionCb(handle: ptr Stream, status: cint) {.cdecl.} =
  let server = cast[TcpServer](handle.data)
  if status < 0 or server.connections >= server.maxConnections or server.connectionCb == nil:
    discard
  else:
    var sock = accept(addr(server.handle), server.domain) do (err: ref NodeError):
      dec(server.connections)
    inc(server.connections)
    server.connectionCb(sock)

proc serve*(server: TcpServer, port: Port, address = "127.0.0.1",
            domain = Domain.AF_INET, backlog = SOMAXCONN) =
  ## Start the process of listening for incoming TCP connections on the specified 
  ## ``address`` and ``port``. 
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
  server.domain = domain
  cond bindAddr(addr(server.handle), port, address, domain)
  cond listen(cast[ptr Stream](addr(server.handle)), cint(backlog), connectionCb)
  



