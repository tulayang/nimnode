#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## TCP handles are used to represent both TCP streams and servers.
##
## ``TCP`` is a ‘subclass’ of ``Stream``.
##
## `TCP handle <libuv 1.10.3-dev API documentation>
## <http://docs.libuv.org/en/v1.x/tcp.html>`_
##
##   See also The ``Stream`` API functions also apply.

import uv_loop, uv_handle, uv_stream, uv_misc

type
  TCP* {.pure, final, importc: "uv_tcp_t", header: "uv.h".} = object ## TCP handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
    sizeOfWriteQueue* {.importc: "write_queue_size".}: csize ## Contains the amount of queued bytes waiting to be sent. Readonly.

proc init*(loop: ptr Loop, handle: ptr TCP): cint {.importc: "uv_tcp_init", header: "uv.h".}
  ## Initialize the handle. No socket is created as of yet.

proc init*(loop: ptr Loop, handle: ptr TCP, flags: cuint): cint {.importc: "uv_tcp_init_ex", header: "uv.h".}
  ## Initialize the handle with the specified flags. At the moment only the lower 8 bits of the flags parameter are used as the
  ## socket domain. A socket will be created for the given domain. If the specified domain is ``AF_UNSPEC`` no socket is created,
  ## just like ``init()``.
  ##
  ## New in version 1.7.0.

proc open*(handle: ptr TCP, sock: SocketHandle): cint {.importc: "uv_tcp_open", header: "uv.h".}
  ## Open an existing file descriptor or SOCKET as a TCP handle.
  ##
  ## Changed in version 1.2.1: the file descriptor is set to non-blocking mode.
  ##
  ##   Note: The passed file descriptor or SOCKET is not checked for its type, but it’s
  ##   required that it represents a valid stream socket.

proc setNoDelay*(handle: ptr TCP, enable: cint): cint {.importc: "uv_tcp_nodelay", header: "uv.h".}
  ## Enable TCP_NODELAY, which disables Nagle’s algorithm.

proc setKeepAlive*(handle: ptr TCP, enable: cint, delay: cuint): cint {.importc: "uv_tcp_keepalive", header: "uv.h".}
  ## Enable / disable TCP keep-alive. `delay` is the initial delay in seconds, ignored when `enable` is zero.

proc simultaneousAccepts*(handle: ptr TCP, enable: cint): cint {.importc: "uv_tcp_simultaneous_accepts", header: "uv.h".}
  ## Enable / disable simultaneous asynchronous accept requests that are queued by the operating system when listening for
  ## new TCP connections.
  ##
  ## This setting is used to tune a TCP server for the desired performance. Having simultaneous accepts can
  ## significantly improve the rate of accepting connections (which is why it is enabled by default) but
  ## may lead to uneven load distribution in multi-process setups.

proc bindAddr*(handle: ptr TCP, sockAddr: ptr SockAddr, flags: cuint): cint {.importc: "uv_tcp_bind", header: "uv.h".}
  ## Bind the handle to an address and port. ``sockAddr`` should point to an initialized struct sockaddr_in or struct sockaddr_in6.
  ##
  ## When the port is already taken, you can expect to see an EADDRINUSE error from either ``bind()``, ``stream.listen()`` or
  ## ``connect()``. That is, a successful call to this function does not guarantee that the call to ``stream.listen()`` or ``connect()``
  ## will succeed as well.
  ##
  ## flags can contain TCP_IPV6ONLY, in which case dual-stack support is disabled and only IPv6 is used.

proc getSockName*(handle: ptr TCP, name: ptr SockAddr, namelen: var cint): cint {.importc: "uv_tcp_getsockname", header: "uv.h".}
  ## Get the current address to which the handle is bound. addr must point to a valid and big enough chunk of memory,
  ## struct sockaddr_storage is recommended for IPv4 and IPv6 support.

proc getPeerName*(handle: ptr TCP, name: ptr SockAddr, namelen: var cint): cint {.importc: "uv_tcp_getpeername", header: "uv.h".}
  ## Get the address of the peer connected to the handle. addr must point to a valid and big enough chunk of memory,
  ## struct sockaddr_storage is recommended for IPv4 and IPv6 support.

proc connect*(req: ptr Connect, handle: ptr TCP, sockAddr: ptr SockAddr, cb: ConnectCb): cint {.importc: "uv_tcp_connect", header: "uv.h".}
  ## Establish an IPv4 or IPv6 TCP connection. Provide an initialized TCP handle and an uninitialized
  ## ``Connect``. addr should point to an initialized struct sockaddr_in or struct sockaddr_in6.
  ##
  ## The callback is made when the connection has been established or when a connection error happened.
