#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Async handles allow the user to “wakeup” the event loop and get a callback called from another thread.
##
## `Async handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/async.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle

type
  Async* {.pure, final, importc: "uv_async_t", header: "uv.h".} = object ## Async handle type.
    loop* {.importc: "loop".}: ptr Loop      ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer   ## Space for user-defined arbitrary data. libuv does not use this field.
  
  AsyncCb* {.pure, final, importc: "uv_async_cb", header: "uv.h".} = proc(handle: Async)
    ## Type definition for callback passed to ``init()``.

proc init*(loop: ptr Loop, handle: ptr Async, cb: AsyncCb): cint {.importc: "uv_async_init", header: "uv.h".}
  ## Initialize the handle. A nil callback is allowed.
  ##
  ##   Note: Unlike other handle initialization functions, it immediately starts the handle.

proc send*(handle: ptr Async): cint {.importc: "uv_async_send", header: "uv.h".}
  ## Wakeup the event loop and call the async handle’s callback.
  ##
  ##   Note: It’s safe to call this function from any thread. The callback will be called on the loop thread.
  ##
  ##   Warning libuv will coalesce calls to ``send()``, that is, not every call to it will yield an 
  ##   execution of the callback. For example: if ``send()`` is called 5 times in a row before the callback
  ##   is called, the callback will only be called once. If ``send()`` is called again after the callback 
  ##   was called, it will be called again.


 