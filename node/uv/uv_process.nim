#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Process handles will spawn a new process and allow the user to control it and establish communication channels 
## with it using streams.
##
## `Process handle <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/process.html>`_
##
##   See also The ``Handle`` API functions also apply.

import uv_loop, uv_handle, uv_stream

when defined(windows):
  type
    Uid* = cuchar
    Gid* = cuchar
else:
  type
    Uid* {.importc: "uid_t", header: "<sys/types.h>".} = int
    Gid* {.importc: "gid_t", header: "<sys/types.h>".} = int

type
  Process* {.pure, final, importc: "uv_process_t", header: "uv.h".} = object ## Process handle type.
    loop* {.importc: "loop".}: ptr Loop      ## Pointer to the ``Loop`` where the handle is running on. Readonly.
    typ* {.importc: "type".}: HandleType ## The ``HandleType``. Readonly.
    data* {.importc: "data".}: pointer   ## Space for user-defined arbitrary data. libuv does not use this field.
    pid* {.importc: "pid".}: cint        ## The PID of the spawned process. It’s set after calling ``spawn()``.
  
  ProcessFlag* = enum ## Flags to be set on the flags field of ``ProcessOptions``.
    prcSetUid = 1 shl 0, ## Set the child process' user id.
    prcSetGid = 1 shl 1, ## Set the child process' group id.
    prcWindowsVerbatimArguments = 1 shl 2, 
      ## Do not wrap any arguments in quotes, or perform any other escaping, when converting the argument list into 
      ## a command line string. This option is only meaningful on Windows systems. On Unix it is silently ignored.
    prcDetached = 1 shl 3, 
      ## Spawn the child process in a detached state - this will make it a process group leader, 
      ## and will effectively enable the child to keep running after the parent exits. Note that the child process 
      ## will still keep the parent's event loop alive unless the parent process calls uv_unref() on the child's 
      ## process handle.
    prcWindowsHide = 1 shl 4
      ## Hide the subprocess console window that would normally be created. This option is only meaningful on Windows 
      ## systems. On Unix it is silently ignored.

  ProcessOptions* {.pure, final, importc: "uv_process_options_t", header: "uv.h".} = object 
    ## Options for spawning the process (passed to ``spawn()``).
    exitCb* {.importc: "exit_cb".}: ExitCb ## Callback called after the process exits.
    file* {.importc: "file".}: cstring ## Path pointing to the program to be executed.
    args* {.importc: "args".}: cstringArray      
      ## Command line arguments. args[0] should be the path to the program. On Windows this uses CreateProcess which
      ## concatenates the arguments into a string this can cause some strange errors. 
    env* {.importc: "env".}: cstringArray ## Environment for the new process. If nil the parents environment is used.
    cwd* {.importc: "cwd".}: cstring ## Current working directory for the subprocess.
    flags* {.importc: "flags".}: cuint ## Various flags that control how ``spawn()`` behaves.
    stdioCount* {.importc: "stdio_count".}: cint ## 
    stdio* {.importc: "stdio".}: ptr StdioContainer 
      ## The stdio field points to an array of StdioContainer structs that describe the file descriptors that 
      ## will be made available to the child process. The convention is that stdio[0] points to stdin, fd 1 
      ## is used for stdout, and fd 2 is stderr.
      ##
      ##   Note: On Windows file descriptors greater than 2 are available to the child process only if 
      ##   the child processes uses the MSVCRT runtime.
    uid* {.importc: "uid".}: Uid
    gid* {.importc: "gid".}: Gid
      ## Libuv can change the child process’ user/group id. This happens only when the appropriate bits are set 
      ## in the flags fields.
      ##   Note: This is not supported on Windows, ``spawn()`` will fail and set the error to ENOTSUP.

  StdioFlag* = enum 
    ## Flags specifying how a stdio should be transmitted to the child process.
    ##
    ## When stdioCreatePipe is specified, stdioReadablePipe and stdioWriteablePipe determine the direction of flow, from 
    ## the child process' perspective. Both flags may be specified to create a duplex data stream.
    stdioIgnore = 0x00, stdioCreatePipe = 0x01, stdioInheritFd = 0x02, stdioInheritStream = 0x04,
    stdioReadablePipe = 0x10, stdioWriteablePipe = 0x20

  StdioContainerData* {.union.} = object
    stream*: ptr Stream
    fd*: cint

  StdioContainer* {.pure, final, importc: "uv_stdio_container_t", header: "uv.h".} = object 
    ## Container for each stdio handle or fd passed to a child proces
    flags* {.importc: "flags".}: cuint ## Flags specifying how the stdio container should be passed to the child. 
    data* {.importc: "data".}: StdioContainerData ## Union containing either the stream or fd to be passed on to the child process.
     
  ExitCb* = proc(handle: ptr Process, exitCode: int64, signal: cint) {.cdecl.}
    ## Type definition for callback passed to ``start()``.

proc disableStdioInheritance*() {.importc: "uv_disable_stdio_inheritance", header: "uv.h".}
  ## Disables inheritance for file descriptors / handles that this process inherited from its parent. The effect is that 
  ## child processes spawned by this process don’t accidentally inherit these handles.
  ##
  ## It is recommended to call this function as early in your program as possible, before the inherited file 
  ## descriptors can be closed or duplicated.
  ##
  ##   Note: This function works on a best-effort basis: there is no guarantee that libuv can discover all file descriptors that
  ##   were inherited. In general it does a better job on Windows than it does on Unix.

proc spawn*(loop: ptr Loop, handle: ptr Process, options: ptr ProcessOptions): cint {.importc: "uv_spawn", header: "uv.h".}
  ## Initializes the process handle and starts the process. If the process is successfully spawned, this function will return 
  ## 0. Otherwise, the negative error code corresponding to the reason it couldn’t spawn is returned.
  ## 
  ## Possible reasons for failing to spawn would include (but not be limited to) the file to execute not existing, not having 
  ## permissions to use the setuid or setgid specified, or not having enough memory to allocate for the new process.
  
proc kill*(handle: ptr Process, signum: cint): cint {.importc: "uv_process_kill", header: "uv.h".}
  ## Sends the specified signal to the given process handle. Check the documentation on Signal handle for signal support, specially 
  ## on Windows.

proc kill*(pid: cint, signum: cint): cint {.importc: "uv_kill", header: "uv.h".}
  ## Sends the specified signal to the given PID. Check the documentation on Signal handle for signal support, specially 
  ## on Windows.


