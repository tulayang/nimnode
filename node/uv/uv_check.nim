#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Check handles will run the given callback once per loop iteration, right after polling for i/o.
##
## `Check handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/check.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle

type
  Check* {.pure, final, importc: "uv_check_t", header: "uv.h".} = object ## Check handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.

  CheckCb* = proc(handle: ptr Check) {.cdecl.}
    ## Type definition for callback passed to ``start()``.

proc init*(loop: ptr Loop, handle: ptr Check): cint {.importc: "uv_check_init", header: "uv.h".}
  ## Initialize the handle.

proc start*(handle: ptr Check, cb: CheckCb): cint {.importc: "uv_check_start", header: "uv.h".}
  ## Start the handle with the given callback.
  
proc stop*(handle: ptr Check): cint {.importc: "uv_check_stop", header: "uv.h".}
  ## Stop the handle, the callback will no longer be called.

