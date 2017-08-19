#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Stream handles provide an abstraction of a duplex communication channel. ``Stream`` is an abstract type, 
## libuv provides 3 stream implementations in the for of ``TCP``, ``Pipe`` and ``TTY``.
##
##   See also The ``Handle`` API functions also apply.
##
## `Stream handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/stream.html>`_

import uv_loop, uv_handle, uv_request, uv_misc

type
  Stream* {.pure, final, importc: "uv_stream_t", header: "uv.h".} = object ## Stream handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
    sizeOfWriteQueue* {.importc: "write_queue_size".}: csize ## Contains the amount of queued bytes waiting to be sent. Readonly.
  
  Connect* {.pure, final, importc: "uv_connect_t", header: "uv.h".} = object ## Connect request type.
    typ* {.importc: "type".}: RequestType ## Indicated the type of request. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.   
    handle* {.importc: "handle".}: ptr Stream ## Pointer to the stream where this connection request is running.

  Shutdown* {.pure, final, importc: "uv_shutdown_t", header: "uv.h".} = object ## Shutdown request type.
    typ* {.importc: "type".}: RequestType ## Indicated the type of request. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.   
    handle* {.importc: "handle".}: ptr Stream ## Pointer to the stream where this shutdown request is running.
  
  Write* {.pure, final, importc: "uv_write_t", header: "uv.h".} = object ## Write request type.
    ## Careful attention must be paid when reusing objects of this type. When a stream is in non-blocking mode, write requests
    ## sent with ``write()`` will be queued. Reusing objects at this point is undefined behaviour. It is safe to reuse the 
    ## ````Write`` object only after the callback passed to ``write()`` is fired.
    typ* {.importc: "type".}: RequestType ## Indicated the type of request. Readonly.
    data* {.importc: "data".}: pointer    ## Space for user-defined arbitrary data. libuv does not use this field.   
    handle* {.importc: "handle".}: ptr Stream ## Pointer to the stream where this write request is running.
    sendHandle* {.importc: "send_handle".}: ptr Stream ## Pointer to the stream being sent using this write request.

  ReadCb* = proc(handle: ptr Stream, nread: cssize, buf: ptr Buffer) {.cdecl.}
    ## Callback called when data was read on a stream. 
    ##
    ## nread is > 0 if there is data available or < 0 on error. When we’ve reached EOF, nread will be set to ``EOF``. When nread < 0, 
    ## the buf parameter might not point to a valid buffer; in that case buf.len and buf.base are both set to 0.
    ##
    ##   Note nread might be 0, which does not indicate an error or EOF. This is equivalent to EAGAIN or EWOULDBLOCK under read(2). 
    ##
    ## The callee is responsible for stopping closing the stream when an error happens by calling ``readStop()`` or ``handle.close()``. 
    ## Trying to read from the stream again is undefined.
    ##
    ## The callee is responsible for freeing the buffer, libuv does not reuse it. The buffer may be a nil buffer (where buf.base=nil
    ## and buf.len=0) on error.

  WriteCb* = proc(req: ptr Write, status: cint) {.cdecl.}
    ## Callback called after data was written on a stream. status will be 0 in case of success, < 0 otherwise.

  ConnectCb* = proc(req: ptr Connect, status: cint) {.cdecl.}
    ## Callback called after a connection started by ``connect()`` is done. status will be 0 in case of success, < 0 otherwise.
  
  ShutdownCb* = proc(req: ptr Shutdown, status: cint) {.cdecl.}
    ## Callback called after a shutdown request has been completed. status will be 0 in case of success, < 0 otherwise.
    
  ConnectionCb* = proc(server: ptr Stream, status: cint) {.cdecl.}
    ## Callback called when a stream server has received an incoming connection. The user can accept the connection by calling 
    ## ``accept()``. status will be 0 in case of success, < 0 otherwise.

proc shutdown*(req: ptr Shutdown, handle: ptr Stream, cb: ShutdownCb): cint {.importc: "uv_shutdown", header: "uv.h".}
  ## Shutdown the outgoing (write) side of a duplex stream. It waits for pending write requests to complete. The handle should refer to
  ## a initialized stream. req should be an uninitialized shutdown request struct. The cb is called after shutdown is complete.

proc listen*(handle: ptr Stream, backlog: cint, cb: ConnectionCb): cint {.importc: "uv_listen", header: "uv.h".}
  ## Start listening for incoming connections. `backlog` indicates the number of connections the kernel might queue, same as 
  ## `listen(2) <http://linux.die.net/man/2/listen>`_. 
  ## When a new incoming connection is received the ``ConnectionCb`` callback is called.
  
proc accept*(server: ptr Stream, client: ptr Stream): cint {.importc: "uv_accept", header: "uv.h".}
  ## This call is used in conjunction with ``listen()`` to accept incoming connections. Call this function after receiving a ``ConnectionCb`` 
  ## to accept the connection. Before calling this function the client handle must be initialized. < 0 return value indicates an error.
  ##
  ## When the ``ConnectionCb`` callback is called it is guaranteed that this function will complete successfully the first time. If you attempt
  ## to use it more than once, it may fail. It is suggested to only call this function once per ``ConnectionCb`` call.
  ##
  ##   Note: server and client must be handles running on the same loop.

proc readStart*(handle: ptr Stream, allocCb: AllocCb, readCb: ReadCb): cint {.importc: "uv_read_start", header: "uv.h".}
  ## Read data from an incoming stream. The ``ReadCb`` callback will be made several times until there is no more data to read or ``readStop()`` is called.
  
proc readStop*(handle: ptr Stream): cint {.importc: "uv_read_stop", header: "uv.h".}
  ## Stop reading data from the stream. The ``ReadCb`` callback will no longer be called.
  ##
  ## This function is idempotent and may be safely called on a stopped stream.

proc write*(req: ptr Write, handle: ptr Stream, bufs: ptr Buffer, nbufs: cuint, cb: WriteCb): cint {.importc: "uv_write", header: "uv.h".}
  ## Write data to stream. Buffers are written in order. Example:
  ##
  ## .. code-block:: nim
  ##
  ##   proc cb(req: Write, status: cint) = 
  ##     # Logic which handles the write result
  ##
  ##   ...
  ##
  ##   Note The memory pointed to by the buffers must remain valid until the callback gets called. This also holds for ``write2()``.

proc write2*(req: ptr Write, handle: ptr Stream, bufs: ptr Buffer, nbufs: cuint, sendhandle: ptr Stream, cb: WriteCb): cint {.importc: "uv_write2", header: "uv.h".}
  ## Extended write function for sending handles over a pipe. The pipe must be initialized with ipc == 1.
  ##
  ## Note sendHandle must be a TCP socket or pipe, which is a server or a connection (listening or connected state). Bound sockets 
  ## or pipes will be assumed to be servers.
  
proc tryWrite*(handle: ptr Stream, bufs: ptr Buffer, nbufs: cuint): cint {.importc: "uv_try_write", header: "uv.h".}
  ## Same as ``write()``, but won’t queue a write request if it can’t be completed immediately.
  ##
  ## Will return either:
  ##
  ## - > 0: number of bytes written (can be less than the supplied buffer size).
  ## - < 0: negative error code (EAGAIN is returned if no data can be sent immediately).

proc isReadable*(handle: ptr Stream): cint {.importc: "uv_is_readable", header: "uv.h".}
  ## Returns 1 if the stream is readable, 0 otherwise.
  
proc isWriteable*(handle: ptr Stream): cint {.importc: "uv_is_writable", header: "uv.h".}
  ## Returns 1 if the stream is writable, 0 otherwise.
    
proc setBlocking*(handle: ptr Stream, blocking: cint): cint {.importc: "uv_stream_set_blocking", header: "uv.h".}
  ## Enable or disable blocking mode for a stream.
  ##
  ## When blocking mode is enabled all writes complete synchronously. The interface remains unchanged otherwise, e.g. completion or 
  ## failure of the operation will still be reported through a callback which is made asynchronously.
  ##
  ##   Warning: Relying too much on this API is not recommended. It is likely to change significantly in the future.
  ##   
  ##   Currently only works on Windows for ``Pipe`` handles. On UNIX platforms, all ``Stream`` handles are supported. 
  ##
  ##   Also libuv currently makes no ordering guarantee when the blocking mode is changed after write requests have already been submitted. 
  ##   Therefore it is recommended to set the blocking mode immediately after opening or creating the stream.
  ##
  ## Changed in version 1.4.0: UNIX implementation added.
