#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Prepare handles will run the given callback once per loop iteration, right before polling for i/o.
##
## `Prepare handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/prepare.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle

type
  Prepare* {.pure, final, importc: "uv_prepare_t", header: "uv.h".} = object ## Prepare handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
  
  PrepareCb* = proc(handle: ptr Prepare) {.cdecl.}
    ## Type definition for callback passed to ``start()``.

proc init*(loop: ptr Loop, handle: ptr Prepare): cint {.importc: "uv_prepare_init", header: "uv.h".}
  ## Initialize the handle.

proc start*(handle: ptr Prepare, cb: PrepareCb): cint {.importc: "uv_prepare_start", header: "uv.h".}
  ## Start the handle with the given callback.
  
proc stop*(handle: ptr Prepare): cint {.importc: "uv_prepare_stop", header: "uv.h".}
  ## Stop the handle, the callback will no longer be called.

