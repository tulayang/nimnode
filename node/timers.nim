#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## This module implements a timer dispatcher and a ticker dispatcher. A timer 
## delays an operation after some milliseconds. A ticker delays an operation to 
## the next iteration.
##
## ..code-block::markdown
##
##   newTimer() -> SetTimeout() -> clearTimeout() 
##              -> ...
##
##   setTimeout() -> clearTimeout()

import uv, error, tables, times, lists, math, asyncfutures

type
  TimerEntity* = object ## Timer object.
    delay: int # milliseconds
    finishAt: float # seconds
    callback: proc() {.closure, gcsafe.}
    joined: bool

  Timer* = distinct ref DoublyLinkedNodeObj[TimerEntity] ## Timer object.

  TimerQueue* = ref object ## Timer queue for one delay.
    handle: uv.Timer
    entities: DoublyLinkedList[TimerEntity]
    delay: int # milliseconds
    length: int
    running: bool
    closed: bool

  TimerDispatcher* = ref object # Dispatcher for timers.
    timers: Table[int, TimerQueue]

  TickerDispatcher* = ref object # Dispatcher for tickers.
    handle: Idle
    running: bool
    callbacks: seq[proc()]

proc newTimerDispatcher*(): TimerDispatcher =
  ## Creates a new dispatcher for timeout tasks.
  new(result)
  GC_ref(result)
  result.timers = initTable[int, TimerQueue]()

var gTimerDispatcher{.threadvar.}: TimerDispatcher
proc getGTimerDispatcher*(): TimerDispatcher =
  ## Returns the global dispatcher of timeout tasks.
  if gTimerDispatcher == nil:
    gTimerDispatcher = newTimerDispatcher()
  return gTimerDispatcher

proc newTimerQueue(delay: int): TimerQueue =
  new(result)
  GC_ref(result)
  result.delay = delay
  result.length = 0
  result.running = false
  result.closed = false
  discard init(getDefaultLoop(), addr(result.handle))
  result.handle.data = cast[pointer](result)

proc closeTQCb(handle: ptr Handle) {.cdecl.} =
  let Q = cast[TimerQueue](handle.data)
  GC_unref(Q)

proc close(Q: TimerQueue) =
  if not Q.closed:
    let gDisp = getGTimerDispatcher()
    Q.running = false
    Q.closed = true
    del(gDisp.timers, Q.delay)
    close(cast[ptr Handle](addr(Q.handle)), closeTQCb)

proc start(Q: TimerQueue, delay: int) {.gcsafe.}

proc startTQCb(handle: ptr uv.Timer) {.cdecl.} =
  let now = epochTime()
  var Q = cast[TimerQueue](handle.data)
  Q.running = false
  for timer in Q.entities.nodes:
    if timer.value.finishAt <= now:
      let callback = timer.value.callback
      remove(Q.entities, timer)
      dec(Q.length)
      timer.value.callback = nil
      timer.value.joined = false
      if callback != nil:
        callback()
    else:
      var timeRemaining = (timer.value.finishAt - epochTime()) * 1000
      if timeRemaining < 0:
        timeRemaining = 0
      start(Q, toInt(ceil(timeRemaining)))
      return
  if Q.length > 0:
    start(Q, Q.delay)
  else:
    close(Q)

proc start(Q: TimerQueue, delay: int) =
  discard start(addr(Q.handle), startTQCb, uint64(delay), 0)
  Q.running = true

proc newTimer*(): Timer =
  ## Creates a new timer. 
  result = Timer(newDoublyLinkedNode(TimerEntity(joined: false)))

proc setTimeout*(T: Timer, delay: int, cb: proc() {.closure, gcsafe.}) =
  ## Sets a new timeout task. ``cb`` will be executed after ``delay`` milliseconds.
  template timer: untyped = (ref DoublyLinkedNodeObj[TimerEntity])(T)
  let gDisp = getGTimerDispatcher()
  let delayOld = timer.value.delay
  if timer.value.joined:
    assert hasKey(gDisp.timers, delayOld) == true
    assert gDisp.timers[delayOld].running == true
    remove(gDisp.timers[delayOld].entities, timer)
    dec(gDisp.timers[delayOld].length)
    if delay != delayOld and gDisp.timers[delayOld].length == 0:
      close(gDisp.timers[delayOld])
  if not hasKey(gDisp.timers, delay):
    gDisp.timers[delay] = newTimerQueue(delay) # 启动一个新的定时器,并且维护一个链表
    start(gDisp.timers[delay], delay)
  append(gDisp.timers[delay].entities, timer)
  inc(gDisp.timers[delay].length)
  timer.value.joined = true
  timer.value.delay = delay
  timer.value.finishAt = epochTime() + delay / 1000
  timer.value.callback = cb

proc setTimeout*(delay: int, cb: proc() {.closure, gcsafe.}): Timer {.discardable.} =
  result = newTimer()
  setTimeout(result, delay, cb)

proc clearTimeout*(T: Timer) =
  ## Clears ``T`` from timeout queue before excution.
  template timer: untyped = (ref DoublyLinkedNodeObj[TimerEntity])(T)
  let gDisp = getGTimerDispatcher()
  let delay = timer.value.delay
  if timer.value.joined:
    assert hasKey(gDisp.timers, delay) == true
    remove(gDisp.timers[delay].entities, timer)
    dec(gDisp.timers[delay].length)
    timer.value.callback = nil
    timer.value.joined = false
    if gDisp.timers[delay].length == 0:
      close(gDisp.timers[delay])

proc newTickerDispatcher*(): TickerDispatcher =
  ## Creates new dispatcher for tickers.
  new(result)
  GC_ref(result)
  result.running = false
  result.callbacks = newSeqOfCap[proc()](64)
  discard init(getDefaultLoop(), addr(result.handle))
  result.handle.data = cast[pointer](result)

var gTickerDispatcher{.threadvar.}: TickerDispatcher
proc getGTickerDispatcher*(): TickerDispatcher =
  if gTickerDispatcher == nil:
    gTickerDispatcher = newTickerDispatcher()
  return gTickerDispatcher

proc startTickerCb(handle: ptr Idle) {.cdecl.} =
  let gDisp = getGTickerDispatcher()
  var callbacks = gDisp.callbacks
  setLen(gDisp.callbacks, 0)
  for callback in callbacks:
    callback()
  if gDisp.callbacks.len == 0:
    discard stop(handle)
    gDisp.running = false

proc callNext*(cb: proc()) {.gcsafe.} = 
  ## ``cb`` will be deferred to the next iteration to excute.
  let gDisp = getGTickerDispatcher()
  add(gDisp.callbacks, cb)
  if not gDisp.running:
    discard start(addr(gDisp.handle), startTickerCb)
    gDisp.running = true

if asyncfutures.getCallSoonProc().isNil:
  asyncfutures.setCallSoonProc(callNext)