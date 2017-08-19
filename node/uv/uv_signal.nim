#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Signal handles implement Unix style signal handling on a per-event loop bases.
##
## Reception of some signals is emulated on Windows:
##
## - SIGINT is normally delivered when the user presses CTRL+C. However, like on Unix, it is not generated when 
##   terminal raw mode is enabled.
## - SIGBREAK is delivered when the user pressed CTRL + BREAK.
## - SIGHUP is generated when the user closes the console window. On SIGHUP the program is given
##   approximately 10 seconds to perform cleanup. After that Windows will unconditionally terminate it.
## - SIGWINCH is raised whenever libuv detects that the console has been resized. SIGWINCH is emulated by libuv 
##   when the program uses a ``Tty`` handle to write to the console. SIGWINCH may not always be delivered in a timely 
##   manner; libuv will only detect size changes when the cursor is being moved. When a readable 
##   ``Tty`` handle is used in raw mode, resizing the console buffer will also trigger a SIGWINCH signal.
##
## Watchers for other signals can be successfully created, but these signals are never received. These signals are: 
## `SIGILL`, `SIGABRT`, `SIGFPE`, `SIGSEGV`, `SIGTERM` and `SIGKILL`.
##
## Calls to raise() or abort() to programmatically raise a signal are not detected by libuv; these 
## will not trigger a signal watcher.
##
##   Note On Linux SIGRT0 and SIGRT1 (signals 32 and 33) are used by the NPTL pthreads library to manage 
##   threads. Installing watchers for those signals will lead to unpredictable behavior and is strongly discouraged. Future
##   versions of libuv may simply reject them.
##
## `Signal handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/signal.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle

type
  Signal* {.pure, final, importc: "uv_signal_t", header: "uv.h".} = object ## Signal handle type.
    loop* {.importc: "loop".}: ptr Loop  ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer   ## Space for user-defined arbitrary data. libuv does not use this field.
    signum* {.importc: "signum".}: cint  ## Signal being monitored by this handle. Readonly.
    
  SignalCb* = proc(handle: ptr Signal, signum: cint) {.cdecl.}
    ## Type definition for callback passed to ``start()``.

proc init*(loop: ptr Loop, handle: ptr Signal): cint {.importc: "uv_signal_init", header: "uv.h".}
  ## Initialize the handle.

proc start*(handle: ptr Signal, cb: SignalCb, signum: cint): cint {.importc: "uv_signal_start", header: "uv.h".}
  ## Start the handle with the given callback, watching for the given signal.
  
proc stop*(handle: ptr Signal): cint {.importc: "uv_signal_stop", header: "uv.h".}
  ## Stop the handle, the callback will no longer be called.

