#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Pipe handles provide an abstraction over local domain sockets on Unix and named pipes on Windows.
##
## ``Pipe`` is a ‘subclass’ of ``Stream``.
##
## `Pipe handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/pipe.html>`_
##
##   See also The ``Stream`` API functions also apply.

import uv_loop, uv_handle, uv_stream

type
  Pipe* {.pure, final, importc: "uv_pipe_t", header: "uv.h".} = object ## Pipe handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
    sizeOfWriteQueue* {.importc: "write_queue_size".}: csize ## Contains the amount of queued bytes waiting to be sent. Readonly.

proc init*(loop: ptr Loop, handle: ptr Pipe, ipc: cint): cint {.importc: "uv_pipe_init", header: "uv.h".}
  ## Initialize a pipe handle. The ipc argument is a boolean to indicate if this pipe will be used for handle passing between processes.

proc open*(handle: ptr Pipe, file: File): cint {.importc: "uv_pipe_open", header: "uv.h".}
  ## Open an existing file descriptor or HANDLE as a pipe.
  ##
  ## Changed in version 1.2.1: the file descriptor is set to non-blocking mode.
  ##
  ##   Note: The passed file descriptor or HANDLE is not checked for its type, but it’s required that it represents a valid pipe.
  
proc bindPipe*(handle: ptr Pipe, name: cstring): cint {.importc: "uv_pipe_bind", header: "uv.h".}
  ## Bind the pipe to a file path (Unix) or a name (Windows).
  ##
  ##   Note: Paths on Unix get truncated to sizeof(sockaddr_un.sun_path) bytes, typically between 92 and 108 bytes.

proc connect*(req: Connect, name: cstring, cb: ConnectCb) {.importc: "uv_pipe_connect", header: "uv.h".}
  ## Connect to the Unix domain socket or the named pipe.
  ##  
  ##   Note: Paths on Unix get truncated to sizeof(sockaddr_un.sun_path) bytes, typically between 92 and 108 bytes.

proc getSockName*(handle: ptr Pipe, buf: cstring, size: var csize): cint {.importc: "uv_pipe_getsockname", header: "uv.h".}
  ## Get the name of the Unix domain socket or the named pipe.
  ##
  ## A preallocated buffer must be provided. The size parameter holds the length of the buffer and it’s set to the 
  ## number of bytes written to the buffer on output. If the buffer is not big enough ENOBUFS will be returned and
  ## len will contain the required size.
  ##
  ## Changed in version 1.3.0: the returned length no longer includes the terminating null byte, and the buffer is not null terminated.

proc getPeerName*(handle: ptr Pipe, buf: cstring, size: var csize): cint {.importc: "uv_pipe_getpeername", header: "uv.h".}
  ## Get the name of the Unix domain socket or the named pipe to which the handle is connected.
  ##
  ## A preallocated buffer must be provided. The size parameter holds the length of the buffer and it’s set to the 
  ## number of bytes written to the buffer on output. If the buffer is not big enough ENOBUFS will be returned and
  ## len will contain the required size.
  ##
  ## New in version 1.3.0.

proc pendingInstances*(handle: ptr Pipe, count: cint): cint {.importc: "uv_pipe_pending_instances", header: "uv.h".}
  ## Set the number of pending pipe instance handles when the pipe server is waiting for connections.
  ##
  ##   Note: This setting applies to Windows only.

proc pendingCount*(handle: ptr Pipe): cint {.importc: "uv_pipe_pending_count", header: "uv.h".}
  
proc pendingType*(handle: ptr Pipe): HandleType {.importc: "uv_pipe_pending_type", header: "uv.h".}
  ## Used to receive handles over IPC pipes.
  ##
  ## First - call ``pendingCount()``, if it’s > 0 then initialize a handle of the given type, 
  ## returned by ``pendingType()`` and call ``accept(pipe, handle)``.
  