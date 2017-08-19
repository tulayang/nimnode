#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Timer are used to schedule callbacks to be called in the future.
##
## `Timer handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/timer.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle

type
  Timer* {.pure, final, importc: "uv_timer_t", header: "uv.h".} = object ## Timer handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.

  TimerCb* = proc(handle: ptr Timer) {.cdecl.}
    ## Type definition for callback passed to ``start()``.

proc init*(loop: ptr Loop, handle: ptr Timer): cint {.importc: "uv_timer_init", header: "uv.h".}
  ## Initialize the handle.

proc start*(handle: ptr Timer, cb: TimerCb, timeout: uint64, repeat: uint64): cint {.importc: "uv_timer_start", header: "uv.h".}
  ## Start the timer. `timeout` and `repeat` are in milliseconds.
  ##
  ## If `timeout` is zero, the callback fires on the next event loop iteration. If `repeat` is non-zero, the callback fires
  ## first after `timeout` milliseconds and then repeatedly after `repeat` milliseconds.
  ##
  ##   Note: Does not update the event loop’s concept of “now”. See ``loop.updateTime()`` for more information.

proc stop*(handle: ptr Timer): cint {.importc: "uv_timer_stop", header: "uv.h".}
  ## Stop the timer, the callback will not be called anymore.

proc again*(handle: ptr Timer): cint {.importc: "uv_timer_again", header: "uv.h".}
  ## Stop the timer, and if it is repeating restart it using the repeat value as the timeout. If the timer has never been
  ## started before it returns EINVAL.

proc setRepeat*(handle: ptr Timer, repeat: uint64) {.importc: "uv_timer_set_repeat", header: "uv.h".}
  ## Set the repeat interval value in milliseconds. The timer will be scheduled to run on the given interval, regardless of
  ## the callback execution duration, and will follow normal timer semantics in the case of a time-slice overrun.
  ##
  ## For example, if a 50ms repeating timer first runs for 17ms, it will be scheduled to run again 33ms later. If other tasks
  ## consume more than the 33ms following the first timer callback, then the callback will run as soon as possible.
  ##
  ##   Note: If the repeat value is set from a timer callback it does not immediately take effect. If the timer was 
  ##   non-repeating before, it will have been stopped. If it was repeating, then the old repeat value will have been used to 
  ##   schedule the next timeout.

proc getRepeat*(handle: ptr Timer): uint64 {.importc: "uv_timer_get_repeat", header: "uv.h".}
  ## Get the timer repeat value.
  