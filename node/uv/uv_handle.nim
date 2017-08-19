#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## ``Handle`` is the base type for all libuv handle types.
##
## Structures are aligned so that any libuv handle can be cast to ``Handle``. All API functions 
## defined here work with any handle type.
##
## `Base handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/handle.html>`_
##
## Reference counting
## ------------------
##
## The libuv event loop (if run in the default mode) will run until there are no active and referenced handles 
## left. The user can force the loop to exit early by unreferencing handles which are active, for example by 
## calling ``unref()`` after calling ``timer.start()``.
##
## A handle can be referenced or unreferenced, the refcounting scheme doesn’t use a counter, so both operations
## are idempotent.
##
## All handles are referenced when active by default, see ``isActive()`` for a more detailed explanation on what
## being active involves.

import uv_loop, uv_misc

type
  Handle* {.pure, final, importc: "uv_handle_t", header: "uv.h".} = object ## The base libuv handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.

  HandleType* = enum ## The kind of the libuv handle.
    hdlUnknowHandle = 0, hdlAsync, hdlCheck, hdlFsEvent, hdlFsPoll, hdlHandle, hdlIdle, hdlNamedPipe,
    hdlPoll, hdlPrepare, hdlProcess, hdlStream, hdlTcp, hdlTimer, hdlTty, hdlUdp, hdlSignal, hdlFile, 
    hdlHandleTypeMax

  AnyHandle* {.pure, final, union, importc: "uv_any_handle", header: "uv.h".} = object
  #   ## Union of all handle types.
  #   async* {.importc: "async".}: Async
  #   check* {.importc: "check".}: Check
  #   fsEvent* {.importc: "fs_event".}: FsEvent
  #   fsPoll* {.importc: "fs_poll".}: FsPoll
  #   handle* {.importc: "handle".}: Handle
  #   idle* {.importc: "idle".}: Idle
  #   pipe* {.importc: "pipe".}: Pipe
  #   poll* {.importc: "poll".}: Poll
  #   prepare* {.importc: "prepare".}: Prepare
  #   process* {.importc: "process".}: Process
  #   stream* {.importc: "stream".}: Stream
  #   tcp* {.importc: "tcp".}: Tcp
  #   timer* {.importc: "timer".}: Timer
  #   tty* {.importc: "tty".}: Tty
  #   udp* {.importc: "udp".}: Udp
  #   signal* {.importc: "signal".}: Signal
  
  AllocCb* = proc(handle: ptr Handle, size: csize, buf: ptr Buffer) {.cdecl.}
    ## Type definition for callback passed to ``stream.readStart()`` and ``udp.recvStart()``. The user must 
    ## allocate memory and fill the supplied Buffer structure. If NULL is assigned as the buffer’s 
    ## base or 0 as its length, a ENOBUFS error will be triggered in the ``udp.RecvCb`` or the 
    ## ``stream.ReadCb`` callback.
    ##
    ## A suggested size (65536 at the moment in most cases) is provided, but it’s just an indication, not 
    ## related in any way to the pending data to be read. The user is free to allocate the amount of memory
    ## they decide.
    ##
    ## As an example, applications with custom allocation schemes such as using freelists, allocation pools 
    ## or slab based allocators may decide to use a different size which matches the memory chunks they 
    ## already have.
    ##
    ## Example:
    ##
    ## .. code-block:: nim
    ##
    ##   proc myAllocCb(handle: ptr Handle, size: csize, buf: ptr Buffer) =
    ##     buf.base = alloc(size)
    ##     buf.len = size

  CloseCb* = proc(handle: ptr Handle) {.cdecl.}
    ## Type definition for callback passed to ``close()``.

  WalkCb* = proc(handle: ptr Handle, arg: pointer) {.cdecl.}
    ## Type definition for callback passed to ``walk()``.

#proc guessHandle*(file: FileHandle): HandleType {.importc: "uv_guess_handle", header: "uv.h".}
  ## Used to detect what type of stream should be used with a given file descriptor. Usually 
  ## this will be used during initialization to guess the type of the stdio streams.
  ##
  ## For `isatty(3) <http://linux.die.net/man/3/isatty>`_ equivalent functionality use this 
  ## function and test for ``hdlTty``.
  
proc walk*(loop: ptr Loop, cb: WalkCb, arg: pointer) {.importc: "uv_walk", header: "uv.h".}
  ## Walk the list of handles: ``cb`` will be executed with the given ``arg``.

proc isActive*(handle: ptr Handle): cint {.importc: "uv_is_active", header: "uv.h".}
  ## Returns non-zero if the handle is active, zero if it’s inactive. What “active” means depends on the type
  ## of handle:
  ## - A Async handle is always active and cannot be deactivated, except by closing it with close().
  ## - A Pipe, Tcp, Udp, etc. handle - basically any handle that deals with i/o - is active when it is doing 
  ##   something that involves i/o, like reading, writing, connecting, accepting new connections, etc.
  ## - A Check, Idle, Timer, etc. handle is active when it has been started with a call to check.start(), 
  ##   idle.start(), etc.
  ##
  ## Rule of thumb: if a handle of type Foo has a foo.start() function, then it’s active from the moment
  ## that function is called. Likewise, foo.stop() deactivates the handle again.

proc isClosing*(handle: ptr Handle): cint {.importc: "uv_is_closing", header: "uv.h".} 
  ## Returns non-zero if the handle is closing or closed, zero otherwise.
  ##
  ##   Note: This function should only be used between the initialization of the handle and the arrival of the
  #    close callback.

proc close*(handle: ptr Handle, cb: CloseCb) {.importc: "uv_close", header: "uv.h".} 
  ## Request handle to be closed. cb will be called asynchronously after this call. This must be called on each
  ## handle before memory is released.
  ##
  ## Handles that wrap file descriptors are closed immediately but cb will still be deferred to the next 
  ## iteration of the event loop. It gives you a chance to free up any resources associated with the handle.
  ##
  ## In-progress requests, like Connect or Write, are cancelled and have their callbacks called asynchronously 
  ## with status=ECANCELED.

proc refHandle*(handle: ptr Handle) {.importc: "uv_ref", header: "uv.h".} 
  ## Reference the given handle. References are idempotent, that is, if a handle is already referenced calling
  ## this function again will have no effect.

proc unrefHandle*(handle: ptr Handle) {.importc: "uv_unref", header: "uv.h".} 
  ## Un-reference the given handle. References are idempotent, that is, if a handle is already referenced calling
  ## this function again will have no effect.

proc hasRefHandle*(handle: ptr Handle): cint {.importc: "uv_has_ref", header: "uv.h".} 
  ## Returns non-zero if the handle referenced, zero otherwise.

proc sizeofHandle*(typ: HandleType): csize {.importc: "uv_handle_size", header: "uv.h".} 
  ## Returns the size of the given handle type. Useful for FFI binding writers who don’t want to know the structure
  ## layout.

proc sizeofSendBuffer*(handle: ptr Handle, value: var cint): cint {.importc: "uv_send_buffer_size", header: "uv.h".} 
  ## Gets or sets the size of the send buffer that the operating system uses for the socket. 
  ##
  ## If value == 0, it will return the current send buffer size, otherwise it will use value to set the new send
  ## buffer size.
  ##
  ## This function works for Tcp, Pipe and Udp handles on Unix and for Tcp and Udp handles on Windows.
  ##
  ##   Note: Linux will set double the size and return double the size of the original set value.

proc sizeofRecvBuffer*(handle: ptr Handle, value: var cint): cint {.importc: "uv_recv_buffer_size", header: "uv.h".} 
  ## Gets or sets the size of the receive buffer that the operating system uses for the socket. 
  ##
  ## If value == 0, it will return the current receive buffer size, otherwise it will use value to set the new receive
  ## buffer size.
  ##
  ## This function works for Tcp, Pipe and Udp handles on Unix and for Tcp and Udp handles on Windows.
  ##
  ##   Note: Linux will set double the size and return double the size of the original set value.

proc fileno*(handle: ptr Handle, fd: var FD): csize {.importc: "uv_fileno", header: "uv.h".} 
  ## Gets the platform dependent file descriptor equivalent.
  ##
  ## The following handles are supported: Tcp, Pipes, Tty, Udp and Poll. Passing any other handle type
  ## will fail with EINVAL.
  ##
  ## If a handle doesn’t have an attached file descriptor yet or the handle itself has been closed, this 
  ## function will return EBADF.
  ##
  ##   Warning: Be very careful when using this function. libuv assumes it’s in control of the 
  ##   file descriptor so any change to it may lead to malfunction.

proc printAllHandles*(loop: ptr Loop, stream: File) {.importc: "uv_print_all_handles", header: "uv.h".}
  ## Prints all handles associated with the given loop to the given stream.
  ##
  ## Example:
  ##  
  ## .. code-block::nim
  ##
  ##   printAllHandles(defaultLoop(), stderr)
  ##
  ##   [--I] signal   0x1a25ea8
  ##   [-AI] async    0x1a25cf0
  ##   [R--] idle     0x1a7a8c8
  ##   
  ## The format is [flags] handle-type handle-address. For flags:
  ##
  ## - R is printed for a handle that is referenced
  ## - A is printed for a handle that is active
  ## - I is printed for a handle that is internal
  ##
  ##   Warning: This function is meant for ad hoc debugging, there is no API/ABI stability guarantees.
  ##
  ## *New in version 1.8.0.*

proc printActiveHandles*(loop: ptr Loop, stream: File) {.importc: "uv_print_active_handles", header: "uv.h".}
  ## This is the same as ``printAllHandles()`` except only active handles are printed.
  ##
  ##   Warning: This function is meant for ad hoc debugging, there is no API/ABI stability guarantees.
  ##
  ## *New in version 1.8.0.*
  