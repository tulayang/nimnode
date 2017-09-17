#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## Loop is the central part of functionality which depends on libuv event loop.
## It takes care of polling for i/o and scheduling callbacks to be run 
## based on different sources of events.

import uv, error

proc runLoop*() =
  ## Begins the global dispatcher poll loop until there are no more active and
  ## referenced opration.
  let err = run(getDefaultLoop(), runDefault)
  if err < 0:
    raise newNodeError(err)

when not defined(nodeSigPipe) and defined(posix):
  import posix
  var SIG_IGN* {.importc, header: "<signal.h>".}: proc (x: cint) {.noconv.}
  signal(SIGPIPE, SIG_IGN) # Ignore ``EPIPE`` caused by ``uv_write()`` on linux