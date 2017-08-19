#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## FS Poll handles allow the user to monitor a given path for changes. Unlike ``FsEvent``, fs poll handles use stat to detect when a file
## has changed so they can work on file systems where fs event handles can’t.
##
## `FSPoll handle <libuv 1.10.3-dev API documentation>
## <http://docs.libuv.org/en/v1.x/fs_poll.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle, uv_misc

type Stat = object # TODO

type
  FSPoll* {.pure, final, importc: "uv_fs_poll_t", header: "uv.h".} = object ## Fs Poll handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.

  FSPollCb* = proc(handle: ptr FSPoll, status: cint, prev: ptr Stat, curr: ptr Stat) {.cdecl.}
    ## Callback passed to ``pollstart()`` which will be called repeatedly after the handle is started, when any change happens to the monitored path.
    ##
    ## The callback is invoked with status < 0 if path does not exist or is inaccessible. The watcher is not stopped but your callback is not
    ## called again until something changes (e.g. when the file is created or the error reason changes).
    ##
    ## When status == 0, the callback receives pointers to the old and new ``Stat`` structs. They are valid for the duration of the callback only.

proc init*(loop: ptr Loop, handle: ptr FSPoll): cint {.importc: "uv_fs_poll_init", header: "uv.h".}
  ## Initialize the handle.

proc start*(handle: ptr FSPoll, cb: FSPollCb, path: cstring, interval: cuint): cint {.importc: "uv_fs_poll_start", header: "uv.h".}
  ## Check the file at path for changes every interval milliseconds.
  ##
  ##   Note: For maximum portability, use multi-second intervals. Sub-second intervals will not detect all changes on many file systems.

proc stop*(handle: ptr FSPoll): cint {.importc: "uv_fs_poll_stop", header: "uv.h".}
  ## Stop the handle, the callback will no longer be called.

proc getPath*(handle: ptr FSPoll, buffer: cstring, size: var csize): cint {.importc: "uv_fs_poll_getpath", header: "uv.h".}
  ## Get the path being monitored by the handle. The buffer must be preallocated by the user. Returns 0 on success or an error code < 0 in case of failure.
  ## Ouv_fs_poll.getPathn success, buffer will contain the path and size its length. If the buffer is not big enough ENOBUFS will be returned and len will be set to
  ## the required size.
  ##
  ## Changed in version 1.3.0: the returned length no longer includes the terminating null byte, and the buffer is not null terminated.