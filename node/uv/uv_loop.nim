#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## The event loop is the central part of libuv’s functionality. It takes care of polling  
## for i/o and scheduling callbacks to be run based on different sources of events.
##
## `Event loop <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/loop.html>`_

type
  Loop* {.pure, final, importc: "uv_loop_t", header: "uv.h".} = object ## Loop data type.
    data* {.importc: "data".}: pointer
      ## Space for user-defined arbitrary data. libuv does not use this field. libuv does,
      ## however, initialize it to ``nil`` in ``init()``, and it poisons the value (on debug 
      ## builds) on ``close()``.

  RunMode* = enum # Mode used to run the loop with ``run()``.
    runDefault = 0, runOnce, runNoWait  

  LoopOption* = enum ## Used by ``configure()``.
    optBlockSignal = 0
 
proc init*(loop: ptr Loop): cint {.importc: "uv_loop_init", header: "uv.h".}
  ## Initializes the given Loop structure.

proc configure*(loop: ptr Loop, option: LoopOption, signal: cint): cint {.
  importc: "uv_loop_configure", header: "uv.h".}
  ## Set additional loop options. You should normally call this before the first call to 
  ## ``run()`` unless mentioned otherwise.
  ##
  ## Returns 0 on success or a ``E*`` error code on failure. Be prepared to handle ``ENOSYS``; it 
  ## means the loop option is not supported by the platform.
  ##
  ## Supported options:
  ##
  ## - optBlockSignal: Block a signal when polling for new events. The second argument to 
  ##   ``configure()`` is the signal number.
  ##
  ##   This operation is currently only implemented for ``SIGPROF`` signals, to suppress  
  ##   unnecessary wakeups when using a sampling profiler. Requesting other signals will 
  ##   fail with ``EINVAL``.

proc close*(loop: ptr Loop): cint {.importc: "uv_loop_close", header: "uv.h".}
  ## Releases all internal loop resources. Call this function only when the loop has 
  ## finished executing and all open handles and requests have been closed, or it will 
  ## return ``EBUSY``. After this function returns, the user can free the memory allocated
  ## for the loop.  

proc getDefaultLoop*(): ptr Loop {.importc: "uv_default_loop", header: "uv.h".}
  ## Returns the initialized default loop. It may return Nil in case of allocation failure.
  ##
  ## This function is just a convenient way for having a global loop throughout an application, 
  ## the default loop is in no way different than the ones initialized with ``init()``. As
  ## such, the　default loop can (and should) be closed with ``close()`` so the resources 
  ## associated with it are freed.

proc run*(loop: ptr Loop, mode: RunMode): cint {.importc: "uv_run", header: "uv.h".}
  ## This function runs the event loop. It will act differently depending on the specified mode:
  ##
  ## - runDefault: Runs the event loop until there are no more active and referenced handles or requests.
  ##   Returns non-zero if ``stop()`` was called and there are still active handles or requests. Returns
  ##   zero in all other cases.
  ## - runOnce: Poll for i/o once. Note that this function blocks if there are no pending callbacks. 
  ##   Returns zero when done (no active handles or requests left), or non-zero if more callbacks 
  ##   are expected (meaning you should run the event loop again sometime in the future).
  ## - runNoWait: Poll for i/o once but don’t block if there are no pending callbacks. Returns zero if 
  ##   done (no active handles or requests left), or non-zero if more callbacks are expected 
  ##   (meaning you should run the event loop again sometime in the future).

proc isAlive*(loop: ptr Loop): cint {.importc: "uv_loop_alive", header: "uv.h".}
  ## Returns non-zero if there are active handles or request in the loop.

proc stop*(loop: ptr Loop) {.importc: "uv_stop", header: "uv.h".}
  ##　Stop the event loop, causing ``run()`` to end as soon as possible. This will happen not sooner than the
  ## next loop iteration. If this function was called before blocking for i/o, the loop won’t block for 
  ## i/o on this iteration.

proc sizeofLoop*(): csize {.importc: "uv_loop_size", header: "uv.h".}
  ## Returns the size of the Loop structure. Useful for FFI binding writers who don’t want to know the
  ## structure layout.

proc getBackendFd*(loop: ptr Loop): cint {.importc: "uv_backend_fd", header: "uv.h".}
  ## Get backend file descriptor. Only kqueue, epoll and event ports are supported.
  ##
  ## This can be used in conjunction with ``run(loop, runNoWait)`` to poll in one thread and run the 
  ## event loop’s callbacks in another see test/test-embed.c for an example.
  ##
  ##   Note: Embedding a kqueue fd in another kqueue pollset doesn’t work on all platforms. It’s not an error
  ##   to add the fd but it never generates events.

proc getBackendTimeout*(loop: ptr Loop): cint {.importc: "uv_backend_timeout", header: "uv.h".}
  ## Get the poll timeout. The return value is in milliseconds, or -1 for no timeout.

proc now*(loop: ptr Loop): uint64 {.importc: "uv_now", header: "uv.h".}
  ## Return the current timestamp in milliseconds. The timestamp is cached at the start of the event loop 
  ## tick, see ``updateTime()`` for details and rationale.
  ##
  ## The timestamp increases monotonically from some arbitrary point in time. Don’t make assumptions about the
  ## starting point, you will only get disappointed.
  ##
  ##   Note: Use ``hrtime()`` if you need sub-millisecond granularity.

proc updateTime*(loop: ptr Loop) {.importc: "uv_update_time", header: "uv.h".}
  ## Update the event loop’s concept of “now”. Libuv caches the current time at the start of the event loop
  ## tick in order to reduce the number of time-related system calls.
  ##
  ## You won’t normally need to call this function unless you have callbacks that block the event loop for 
  ## longer periods of time, where “longer” is somewhat subjective but probably on the order of a millisecond 
  ## or more.





