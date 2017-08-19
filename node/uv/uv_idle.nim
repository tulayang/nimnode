#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Idle handles will run the given callback once per loop iteration, right before the ``Prepare`` handle.
##
##   Note: The notable difference with prepare handles is that when there are active idle handles, the 
##   loop will perform a zero timeout poll instead of blocking for i/o.
##
##   Warning: Despite the name, idle handles will get their callbacks called on every loop iteration, not
##   when the loop is actually “idle”.
##
## `Idle handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/idle.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle

type
  Idle* {.pure, final, importc: "uv_idle_t", header: "uv.h".} = object ## Idle handle type.
    loop* {.importc: "loop".}: ptr Loop      ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer   ## Space for user-defined arbitrary data. libuv does not use this field.

  IdleCb* = proc(handle: ptr Idle) {.cdecl.}
    ## Type definition for callback passed to ``start()``.

proc init*(loop: ptr Loop, handle: ptr Idle): cint {.importc: "uv_idle_init", header: "uv.h".}
  ## Initialize the handle.

proc start*(handle: ptr Idle, cb: IdleCb): cint {.importc: "uv_idle_start", header: "uv.h".}
  ## Start the handle with the given callback.
  
proc stop*(handle: ptr Idle): cint {.importc: "uv_idle_stop", header: "uv.h".}
  ## Stop the handle, the callback will no longer be called.

