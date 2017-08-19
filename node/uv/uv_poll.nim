#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Poll handles used to watch file descriptors for readability, writability and disconnection similar to the 
## purpose of `poll2 <http://linux.die.net/man/2/poll>`_.
##
## The purpose of poll handles is to enable integrating external libraries that rely on the event loop to 
## signal it about the socket status changes, like c-ares or libssh2. Using Poll for any other purpose is not
## recommended; ``Tcp``, ``Udp``, etc. provide an implementation that is faster and more scalable than what can be 
## achieved with ``Poll``, especially on Windows.
##
## It is possible that poll handles occasionally signal that a file descriptor is readable or writable 
## even when it isn’t. The user should therefore always be prepared to handle EAGAIN or equivalent when it attempts
## to read from or write to the fd.
##
## It is not okay to have multiple active poll handles for the same socket, this can cause libuv to 
## busyloop or otherwise malfunction.
##
## The user should not close a file descriptor while it is being polled by an active poll handle. This can cause the 
## handle to report an error, but it might also start polling another socket. However the fd can be safely closed
## immediately after a call to ``stop()`` or ``loop.close()``.
##
##   Note: On windows only sockets can be polled with poll handles. On Unix any file descriptor that would
##   be accepted by `poll2 <http://linux.die.net/man/2/poll>`_ can be used.
##
##   Note: On AIX, watching for disconnection is not supported.
##
## `Poll handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/poll.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle, uv_misc

type
  Poll* {.pure, final, importc: "uv_poll_t", header: "uv.h".} = object ## Poll handle type.
    loop* {.importc: "loop".}: ptr Loop      ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer   ## Space for user-defined arbitrary data. libuv does not use this field.

  PollEvent* = enum ## Poll event types
    peReadable = 1, peWriteable = 2, peDisconnect = 4

  PollCb* = proc(handle: ptr Poll, status: cint, events: cint) {.cdecl.}
    ## Type definition for callback passed to ``start()``.

proc init*(loop: ptr Loop, handle: ptr Poll, fd: cint): cint {.importc: "uv_poll_init", header: "uv.h".}
  ## Initialize the handle using a file descriptor.
  ##
  ## Changed in version 1.2.2: the file descriptor is set to non-blocking mode.

proc initWithSocket*(loop: ptr Loop, handle: ptr Poll, socket: SocketHandle): cint {.importc: "uv_poll_init_socket", header: "uv.h".}
  ## Initialize the handle using a socket descriptor. On Unix this is identical to ``init()``. On windows it takes 
  ## a SOCKET handle.
  ##
  ## Changed in version 1.2.2: the socket is set to non-blocking mode.

proc start*(handle: ptr Poll, events: cint, cb: PollCb): cint {.importc: "uv_poll_start", header: "uv.h".}
  ## Start polling the file descriptor. `events` is a bitmask consisting made up of peReadable, peWriteable and 
  ## peDisconnect. As soon as an event is detected the callback will be called with status set to 0, and the detected events 
  ## set on the events field.
  ##
  ## The peDisconnect event is optional in the sense that it may not be reported and the user is free to ignore it, but it 
  ## can help optimize the shutdown path because an extra read or write call might be avoided.
  ## 
  ## If an error happens while polling, status will be < 0 and corresponds with one of the E* error codes (see 
  ## Error handling). The user should not close the socket while the handle is active. If the user does that anyway, the 
  ## callback may be called reporting an error status, but this is not guaranteed.
  ##
  ##   Note Calling ``start()`` on a handle that is already active is fine. Doing so will update the events mask that 
  ##   is being watched for.
  ##
  ##   Note: Though peDisconnect can be set, it is unsupported on AIX and as such will not be set on the events field in
  ##   the callback.
  ##
  ## Changed in version 1.9.0: Added the peDisconnect event.
  
proc stop*(handle: ptr Poll): cint {.importc: "uv_poll_stop", header: "uv.h".}
  ## Stop polling the file descriptor, the callback will no longer be called.

