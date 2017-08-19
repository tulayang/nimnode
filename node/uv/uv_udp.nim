#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## UDP handles encapsulate UDP communication for both clients and servers.
##
## `UDP handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/udp.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle, uv_stream, uv_misc

type
  UDP* {.pure, final, importc: "uv_udp_t", header: "uv.h".} = object ## UDP handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
    sizeOfSendQueue* {.importc: "send_queue_size".}: csize 
      ## Number of bytes queued for sending. This field strictly shows how much information is currently queued.
    countOfSendQueue* {.importc: "send_queue_count".}: csize 
      ## Number of send requests currently in the queue awaiting to be processed.

  UDPSend* {.pure, final, importc: "uv_udp_send_t", header: "uv.h".} = object ## UDP send request type.
    handle* {.importc: "handle".}: ptr UDP ## UDP handle where this send request is taking place.

  UDPFlag* = enum ## Flags used in ``bind()`` and ``RecvCb``.
    udpIpv6Only = 1, ## Disables dual stack mode.
    udpPartial = 2,  
      ## Indicates message was truncated because read buffer was too small. The remainder was discarded by the OS. Used in ``RecvCb``.
    udpReuseAddr = 4 
    ## Indicates if SO_REUSEADDR will be set when binding the handle in ``bind()``. This sets the SO_REUSEPORT socket 
    ## flag on the BSDs and OS X. On other Unix platforms, it sets the SO_REUSEADDR flag. What that means is that multiple 
    ## threads or processes can bind to the same address without error (provided they all set the flag) but only 
    ## the last one to bind will receive any traffic, in effect "stealing" the port from the previous listener.

  SendCb* = proc(req: ptr UDPSend, status: cint) {.cdecl.}
    ## Type definition for callback passed to ``send()``, which is called after the data was sent.

  RecvCb* = proc(handle: ptr UDP, nread: cssize, buf: ptr Buffer, sockaddr: ptr SockAddr, flags: cuint) {.cdecl.}
    ## Type definition for callback passed to ``recvStart()``, which is called when the endpoint receives data. 
    ## 
    ## - `handle`: UDP handle 
    ## - `nread`: Number of bytes that have been received. 0 if there is no more data to read. You may discard or repurpose the read buffer.
    ##   Note that 0 may also mean that an empty datagram was received (in this case addr is not NULL). < 0 if a transmission error was detected.  
    ## - `buf`: ``Buffer`` with the received data.
    ## - `sockaddr`: struct sockaddr* containing the address of the sender. Can be nil. Valid for the duration of the callback only.
    ## - `flags`: One or more or’ed UDP_* constants. Right now only UDP_PARTIAL is used.
    ##
    ##   Note: The receive callback will be called with nread == 0 and sockaddr == nil when there is nothing to read, and with 
    ##   nread == 0 and sockaddr != nil when an empty UDP packet is received.

  MemberShip* = enum ## Membership type for a multicast address.
    memberLeaveGroup = 0, memberJoinGroup 

proc init*(loop: ptr Loop, handle: ptr UDP): cint {.importc: "uv_udp_init", header: "uv.h".}
  ## Initialize a new UDP handle. The actual socket is created lazily. Returns 0 on success.

proc init*(loop: ptr Loop, handle: ptr UDP, flags: cuint): cint {.importc: "uv_udp_init_ex", header: "uv.h".}
  ## Initialize the handle with the specified flags. At the moment only the lower 8 bits of the flags parameter are used as the 
  ## socket domain. A socket will be created for the given domain. If the specified domain is AF_UNSPEC no socket is created, 
  ## just like ``init()``.
  ##
  ## New in version 1.7.0.
  
proc open*(handle: ptr UDP, sock: SocketHandle): cint {.importc: "uv_udp_open", header: "uv.h".}
  ## Open an existing file descriptor or SOCKET as a UDP handle.
  ##
  ## Unix only: The only requirement of the sock argument is that it follows the datagram contract (works in 
  ## unconnected mode, supports sendmsg()/recvmsg(), etc). In other words, other datagram-type sockets like 
  ## raw sockets or netlink sockets can also be passed to this function.
  ##
  ## Changed in version 1.2.1: the file descriptor is set to non-blocking mode.
  ##
  ##   Note: The passed file descriptor or SOCKET is not checked for its type, but it’s 
  ##   required that it represents a valid stream socket.

proc bindAddr*(handle: ptr UDP, sockAddr: ptr SockAddr, flags: cuint): cint {.importc: "uv_udp_bind", header: "uv.h".}
  ## Bind the UDP handle to an address and port. returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `sockaddr`: struct sockaddr_in or struct sockaddr_in6 with the address and port to bind to.
  ## - `flags`: Indicate how the socket will be bound, UDP_IPV6ONLY and UDP_REUSEADDR are supported.

proc getSockName*(handle: ptr UDP, name: var SockAddr, namelen: var cint): cint {.importc: "uv_udp_getsockname", header: "uv.h".}
  ## Get the local IP and port of the UDP handle. returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `name`: Pointer to the structure to be filled with the address data. In order to support IPv4 and IPv6 struct sockaddr_storage should be used.
  ## - `namelen`: On input it indicates the data of the name field. On output it indicates how much of it was filled.

proc setMemberShip*(handle: ptr UDP, multicastAddr: cstring, interfaceAddr: cstring, membership: Membership): cint {.importc: "uv_udp_set_membership", header: "uv.h".}
  ## Set membership for a multicast address. Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `multicastAddr`: Multicast address to set membership for.
  ## - `interfaceAddr`: Interface address.
  ## - `membership`: Should be memberLeaveGroup or memberJoinGroup.

proc setMulticastLoop*(handle: ptr UDP, on: cint): cint {.importc: "uv_udp_set_multicast_loop", header: "uv.h".}
  ## Set IP multicast loop flag. Makes multicast packets loop back to local sockets. Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `on`: 1 for on, 0 for off.

proc setMulticastTTL*(handle: ptr UDP, ttl: cint): cint {.importc: "uv_udp_set_multicast_ttl", header: "uv.h".}
  ## Set IP multicast ttl. Makes multicast packets loop back to local sockets. Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `ttl`: 1 through 255.

proc setMulticastInterface*(handle: ptr UDP, interfaceAddr: cstring): cint {.importc: "uv_udp_set_multicast_interface", header: "uv.h".}
  ## Set the multicast interface to send or receive data on. Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `interfaceAddr`: interface address. 

proc setBroadcast*(handle: ptr UDP, on: cint): cint {.importc: "uv_udp_set_broadcast", header: "uv.h".}
  ## Set broadcast on or off. Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `on`: 1 for on, 0 for off.

proc setTTL*(handle: ptr UDP, ttl: cint): cint {.importc: "uv_udp_set_ttl", header: "uv.h".}
  ##Set the time to live. Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `ttl`: 1 through 255.

proc send*(req: ptr UDPSend, handle: ptr UDP, bufs: ptr Buffer, nbufs: cuint, sockAddr: ptr SockAddr, cb: SendCb): cint {.importc: "uv_udp_send", header: "uv.h".}
  ## Send data over the UDP socket. If the socket has not previously been bound with ``bind()`` it will be bound to 0.0.0.0 (the “all interfaces” IPv4 address) and a random port number.
  ## Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `req`: UDP request handle. Need not be initialized.
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `bufs`: List of buffers to send.
  ## - `nbufs`: Number of buffers in bufs.
  ## - `sockAddr`: struct sockaddr_in or struct sockaddr_in6 with the address and port of the remote peer.
  ## - `cb`: Callback to invoke when the data has been sent out.

proc trySend*(handle: ptr UDP, bufs: ptr Buffer, nbufs: cuint, sockAddr: ptr SockAddr, cb: SendCb): cint {.importc: "uv_udp_try_send", header: "uv.h".}
  ## Same as ``send()``, but won’t queue a send request if it can’t be completed immediately. Returns:
  ##
  ## - >= 0: number of bytes sent (it matches the given buffer size). 
  ## - < 0: negative error code (EAGAIN is returned when the message can’t be sent immediately).

proc recvStart*(handle: ptr UDP, allocCb: AllocCb, recvCb: RecvCb): cint {.importc: "uv_udp_recv_start", header: "uv.h".}
  ## Prepare for receiving data. If the socket has not previously been bound with ``bind()`` it is bound to 0.0.0.0 
  ## (the “all interfaces” IPv4 address) and a random port number.
  ## Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
  ## - `allocCb`: Callback to invoke when temporary storage is needed.
  ## - `recvCb`: Callback to invoke with received data.  

proc recvStop*(handle: ptr UDP): cint {.importc: "uv_udp_recv_stop", header: "uv.h".}
  ## Stop listening for incoming datagrams. Returns 0 on success, or an error code < 0 on failure.
  ##
  ## - `handle`: UDP handle. Should have been initialized with ``intit``. 
