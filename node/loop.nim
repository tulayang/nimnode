#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## Loop is the central part of functionality which depends on libuv event loop.
## It takes care of polling for i/o and scheduling callbacks to be run 
## based on different sources of events.

import uv

# proc sleepAsync*(delay: int): Future[void] =
#   ## Schedules execution of the current async procedure after ``delay`` milliseconds.
#   ##
#   ## The procedure will likely not be invoked in precisely ``delay`` milliseconds.
#   var future = newFuture[void]("sleepAsync")
#   result = future
#   discard setTimeout(delay, proc () = complete(future))

# proc nextTick*(): Future[void] =
#   ## Schedules execution of the current async procedure to the next iteration.
#   var future = newFuture[void]()
#   result = future
#   callSoon(proc () = complete(future))

# proc waitFor*[T](fut: Future[T]): T =
#   ## **Blocks** the current thread until the specified future completes.
#   while not fut.finished and run(getDefaultLoop(), runOnce) != 0: discard

proc runLoop*() =
  ## Begins the global dispatcher poll loop until there are no more active and
  ## referenced opration.
  discard run(getDefaultLoop(), runDefault)

when not defined(nodeSigPipe) and defined(posix):
  import posix
  var SIG_IGN* {.importc, header: "<signal.h>".}: proc (x: cint) {.noconv.}
  signal(SIGPIPE, SIG_IGN) # Ignore ``EPIPE`` caused by ``uv_write()`` on linux