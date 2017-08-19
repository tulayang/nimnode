#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## TTY handles represent a stream for the console.
##
## ``TTY`` is a ‘subclass’ of ``Stream``.
##
## `TTY handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/tty.html>`_
##
##   See also The ``Stream`` API functions also apply.

import uv_loop, uv_handle, uv_stream

type
  TTY* {.pure, final, importc: "uv_tty_t", header: "uv.h".} = object ## TTY handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
    sizeOfWriteQueue* {.importc: "write_queue_size".}: csize ## Contains the amount of queued bytes waiting to be sent. Readonly.

  TTYMode* = enum ## TTY mode type
    ttyNormal,    ## Initial/normal terminal mode
    ttyRaw,       ## Raw input mode (On Windows, ENABLE_WINDOW_INPUT is also enabled)
    ttyIO         ## Binary-safe I/O mode for IPC (Unix-only)

proc init*(loop: ptr Loop, handle: ptr TTY, fd: FileHandle, readable: cint): cint {.importc: "uv_tty_init", header: "uv.h".}
  ## Initialize a new TTY stream with the given file descriptor. Usually the file descriptor will be:
  ##
  ## - 0 = stdin
  ## - 1 = stdout
  ## - 2 = stderr
  ##
  ## `readable`, specifies if you plan on calling ``stream.readStart()`` with this stream. stdin is readable, stdout is not.
  ##
  ## On Unix this function will determine the path of the fd of the terminal using 
  ## `ttyname_r(3) <http://linux.die.net/man/3/ttyname_r>`_, open it, and use it if the passed
  ## file descriptor refers to a TTY. This lets libuv put the tty in non-blocking mode without affecting other processes 
  ## that share the tty.
  ##
  ## This function is not thread safe on systems that don’t support ioctl TIOCGPTN or TIOCPTYGNAME, for instance OpenBSD and Solaris.
  ##
  ##   Note: If reopening the TTY fails, libuv falls back to blocking writes for non-readable TTY streams.
  ##
  ## Changed in version 1.9.0:: the path of the TTY is determined by `ttyname_r(3) <http://linux.die.net/man/3/ttyname_r>`_. 
  ## In earlier versions libuv opened /dev/tty instead.
  ##
  ## Changed in version 1.5.0:: trying to initialize a TTY stream with a file descriptor that refers to a file returns EINVAL on UNIX.

proc setMode*(handle: ptr TTY, mode: TTYMode): cint {.importc: "uv_tty_set_mode", header: "uv.h".}
  ## Changed in version 1.2.0:: the mode is specified as a TTYMode value.
  ##
  ## Set the TTY using the specified terminal mode.
  
proc resetTTYMode*(): cint {.importc: "uv_tty_reset_mode", header: "uv.h".}
  ## To be called when the program exits. Resets TTY settings to default values for the next process to take over.
  ##
  ## This function is async signal-safe on Unix platforms but can fail with error code EBUSY if you call it when execution 
  ## is inside ``setMode()``.

proc getWindowSize*(handle: ptr TTY, width: var cint, height: var cint): cint {.importc: "uv_tty_get_winsize", header: "uv.h".}
  ## Gets the current Window size. On success it returns 0.
