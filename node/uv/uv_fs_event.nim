#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## FS Event handles allow the user to monitor a given path for changes, for example, if the file was renamed or there was a generic
## change in it. This handle uses the best backend for the job on each platform.
##
##   Note: For AIX, the non default IBM bos.ahafs package has to be installed. The AIX Event Infrastructure file system 
##   (ahafs) has some limitations:
##   - ahafs tracks monitoring per process and is not thread safe. A separate process must be spawned for each monitor for the same event.
##   - Events for file modification (writing to a file) are not received if only the containing folder is watched.
##
##   See `documentation <http://www.ibm.com/developerworks/aix/library/au-aix_event_infrastructure/>`_ for more details.
##
## `FSEvent handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/fs_event.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle

type
  FSEvent* {.pure, final, importc: "uv_fs_event_t", header: "uv.h".} = object ## Fs Event handle type.
    loop* {.importc: "loop".}: ptr Loop ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.

  FSEventCb* = proc(handle: ptr FSEvent, filename: cstring, events: cint, status: cint) {.cdecl.}
    ## Callback passed to ``start()`` which will be called repeatedly after the handle is started. If the handle was started with a directory the filename
    ## parameter will be a relative path to a file contained in the directory. The events parameter is an ORed mask of FSEventType elements.

  FSEventType* = enum ## Event types that FSEvent handles monitor.
    fevRename = 1, fevChange = 2

  FSEventFlag* = enum ## Flags that can be passed to ``start()`` to control its behavior.
    fsWatchEntry = 1, 
      ## By default, if the fs event watcher is given a directory name, we will
      ## watch for all events in that directory. This flags overrides this behavior
      ## and makes fs_event report only changes to the directory entry itself. This
      ## flag does not affect individual files watched.
      ## This flag is currently not implemented yet on any backend.
    fsStat = 2,
      ## By default uv_fs_event will try to use a kernel interface such as inotify
      ## or kqueue to detect events. This may not work on remote filesystems such
      ## as NFS mounts. This flag makes fs_event fall back to calling stat() on a
      ## regular interval.
      ## This flag is currently not implemented yet on any backend.
    fsRecursive = 4
      ## By default, event watcher, when watching directory, is not registering
      ## (is ignoring) changes in it's subdirectories.
      ## This flag will override this behaviour on platforms that support it.
 
proc init*(loop: ptr Loop, handle: ptr FSEvent): cint {.importc: "uv_fs_event_init", header: "uv.h".}
  ## Initialize the handle.

proc start*(handle: ptr FSEvent, cb: FSEventCb, path: cstring, flags: cuint): cint {.importc: "uv_fs_event_start", header: "uv.h".}
  ## Start the handle with the given callback, which will watch the specified path for changes. flags can be an ORed mask of ``FSEventFlags``.
  ##
  ##  Note: Currently the only supported flag is FS_EVENT_RECURSIVE and only on OSX and Windows.
  
proc stop*(handle: ptr FSEvent): cint {.importc: "uv_fs_event_stop", header: "uv.h".}
  ## Stop the handle, the callback will no longer be called.

proc getPath*(handle: ptr FSEvent, buffer: cstring, size: var csize): cint {.importc: "uv_fs_event_getpath", header: "uv.h".}
  ## Get the path being monitored by the handle. The buffer must be preallocated by the user. Returns 0 on success or an error code < 0 in case of failure. 
  ## On success, buffer will contain the path and size its length. If the buffer is not big enough ENOBUFS will be returned and len will be set to 
  ## the required size.
  ##
  ## Changed in version 1.3.0: the returned length no longer includes the terminating null byte, and the buffer is not null terminated.