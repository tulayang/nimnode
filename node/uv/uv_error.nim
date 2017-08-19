#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## In libuv errors are negative numbered constants. As a rule of thumb, whenever there is a status
## parameter, or an API functions returns an integer, a negative number will imply an error.
##
## When a function which takes a callback returns an error, the callback will never be called.
##
##   Note Implementation detail: on Unix error codes are the negated errno (or -errno), while on
##   Windows they are defined by libuv to arbitrary negative numbers.
##
## `Error handling <libuv 1.10.3-dev API documentation> <http://docs.libuv.org/en/v1.x/errors.html>`_

var
  E2BIG* {.importc: "UV_E2BIG", header: "uv.h".}: cint
    ## argument list too long
  EACCES* {.importc: "UV_EACCES", header: "uv.h".}: cint
    ## permission denied
  EADDRINUSE* {.importc: "UV_EADDRINUSE", header: "uv.h".}: cint
    ## address already in use
  EADDRNOTAVAIL* {.importc: "UV_EADDRNOTAVAIL", header: "uv.h".}: cint
    ## address not available
  EAFNOSUPPORT* {.importc: "UV_EAFNOSUPPORT", header: "uv.h".}: cint
    ## address family not supported
  EAGAIN* {.importc: "UV_EAGAIN", header: "uv.h".}: cint
    ## resource temporarily unavailable
  EAI_ADDRFAMILY* {.importc: "UV_EAI_ADDRFAMILY", header: "uv.h".}: cint
    ## address family not supported
  EAI_AGAIN* {.importc: "UV_EAI_AGAIN", header: "uv.h".}: cint
    ## temporary failure
  EAI_BADFLAGS* {.importc: "UV_EAI_BADFLAGS", header: "uv.h".}: cint
    ## bad ai_flags value
  EAI_BADHINTS* {.importc: "UV_EAI_BADHINTS", header: "uv.h".}: cint
    ## invalid value for hints
  EAI_CANCELED* {.importc: "UV_EAI_CANCELED", header: "uv.h".}: cint
    ## request canceled
  EAI_FAIL* {.importc: "UV_EAI_FAIL", header: "uv.h".}: cint
    ## permanent failure
  EAI_FAMILY* {.importc: "UV_EAI_FAMILY", header: "uv.h".}: cint
    ## ai_family not supported
  EAI_MEMORY* {.importc: "UV_EAI_MEMORY", header: "uv.h".}: cint
    ## out of memory
  EAI_NODATA* {.importc: "UV_EAI_NODATA", header: "uv.h".}: cint
    ## no address
  EAI_NONAME* {.importc: "UV_EAI_NONAME", header: "uv.h".}: cint
    ## unknown node or service
  EAI_OVERFLOW* {.importc: "UV_EAI_OVERFLOW", header: "uv.h".}: cint
    ## argument buffer overflow
  EAI_PROTOCOL* {.importc: "UV_EAI_PROTOCOL", header: "uv.h".}: cint
    ## resolved protocol is unknown
  EAI_SERVICE* {.importc: "UV_EAI_SERVICE", header: "uv.h".}: cint
    ## service not available for socket type
  EAI_SOCKTYPE* {.importc: "UV_EAI_SOCKTYPE", header: "uv.h".}: cint
    ## socket type not supported
  EALREADY* {.importc: "UV_EALREADY", header: "uv.h".}: cint
    ## connection already in progress
  EBADF* {.importc: "UV_EBADF", header: "uv.h".}: cint
    ## bad file descriptor
  EBUSY* {.importc: "UV_EBUSY", header: "uv.h".}: cint
    ## resource busy or locked
  ECANCELED* {.importc: "UV_ECANCELED", header: "uv.h".}: cint
    ## operation canceled
  ECHARSET* {.importc: "UV_ECHARSET", header: "uv.h".}: cint
    ## invalid Unicode character
  ECONNABORTED* {.importc: "UV_ECONNABORTED", header: "uv.h".}: cint
    ## software caused connection abort
  ECONNREFUSED* {.importc: "UV_ECONNREFUSED", header: "uv.h".}: cint
    ## connection refused
  ECONNRESET* {.importc: "UV_ECONNRESET", header: "uv.h".}: cint
    ## connection reset by peer
  EDESTADDRREQ* {.importc: "UV_EDESTADDRREQ", header: "uv.h".}: cint
    ## destination address required
  EEXIST* {.importc: "UV_EEXIST", header: "uv.h".}: cint
    ## file already exists
  EFAULT* {.importc: "UV_EFAULT", header: "uv.h".}: cint
    ## bad address in system call argument
  EFBIG* {.importc: "UV_EFBIG", header: "uv.h".}: cint
    ## file too large
  EHOSTUNREACH* {.importc: "UV_EHOSTUNREACH", header: "uv.h".}: cint
    ## host is unreachable
  EINTR* {.importc: "UV_EINTR", header: "uv.h".}: cint
    ## interrupted system call
  EINVAL* {.importc: "UV_EINVAL", header: "uv.h".}: cint
    ## invalid argument
  EIO* {.importc: "UV_EIO", header: "uv.h".}: cint
    ## i/o error
  EISCONN* {.importc: "UV_EISCONN", header: "uv.h".}: cint
    ## socket is already connected
  EISDIR* {.importc: "UV_EISDIR", header: "uv.h".}: cint
    ## illegal operation on a directory
  ELOOP* {.importc: "UV_ELOOP", header: "uv.h".}: cint
    ## too many symbolic links encountered
  EMFILE* {.importc: "UV_EMFILE", header: "uv.h".}: cint
    ## too many open files
  EMSGSIZE* {.importc: "UV_EMSGSIZE", header: "uv.h".}: cint
    ## message too long
  ENAMETOOLONG* {.importc: "UV_ENAMETOOLONG", header: "uv.h".}: cint
    ## name too long
  ENETDOWN* {.importc: "UV_ENETDOWN", header: "uv.h".}: cint
    ## network is down
  ENETUNREACH* {.importc: "UV_ENETUNREACH", header: "uv.h".}: cint
    ## network is unreachable
  ENFILE* {.importc: "UV_ENFILE", header: "uv.h".}: cint
    ## file table overflow
  ENOBUFS* {.importc: "UV_ENOBUFS", header: "uv.h".}: cint
    ## no buffer space available
  ENODEV* {.importc: "UV_ENODEV", header: "uv.h".}: cint
    ## no such device
  ENOENT* {.importc: "UV_ENOENT", header: "uv.h".}: cint
    ## no such file or directory
  ENOMEM* {.importc: "UV_ENOMEM", header: "uv.h".}: cint
    ## not enough memory
  ENONET* {.importc: "UV_ENONET", header: "uv.h".}: cint
    ## machine is not on the network
  ENOPROTOOPT* {.importc: "UV_ENOPROTOOPT", header: "uv.h".}: cint
    ## protocol not available
  ENOSPC* {.importc: "UV_ENOSPC", header: "uv.h".}: cint
    ## no space left on device
  ENOSYS* {.importc: "UV_ENOSYS", header: "uv.h".}: cint
    ## function not implemented
  ENOTCONN* {.importc: "UV_ENOTCONN", header: "uv.h".}: cint
    ## socket is not connected
  ENOTDIR* {.importc: "UV_ENOTDIR", header: "uv.h".}: cint
    ## not a directory
  ENOTEMPTY* {.importc: "UV_ENOTEMPTY", header: "uv.h".}: cint
    ## directory not empty
  ENOTSOCK* {.importc: "UV_ENOTSOCK", header: "uv.h".}: cint
    ## socket operation on non-socket
  ENOTSUP* {.importc: "UV_ENOTSUP", header: "uv.h".}: cint
    ##　operation not supported on socket
  EPERM* {.importc: "UV_EPERM", header: "uv.h".}: cint
    ## operation not permitted
  EPIPE* {.importc: "UV_EPIPE", header: "uv.h".}: cint
    ## broken pipe
  EPROTO* {.importc: "UV_EPROTO", header: "uv.h".}: cint
    ## protocol error
  EPROTONOSUPPORT* {.importc: "UV_EPROTONOSUPPORT", header: "uv.h".}: cint
    ## protocol not supported
  EPROTOTYPE* {.importc: "UV_EPROTOTYPE", header: "uv.h".}: cint
    ## protocol wrong type for socket
  ERANGE* {.importc: "UV_ERANGE", header: "uv.h".}: cint
    ## result too large
  EROFS* {.importc: "UV_EROFS", header: "uv.h".}: cint
    ## read-only file system
  ESHUTDOWN* {.importc: "UV_ESHUTDOWN", header: "uv.h".}: cint
    ## cannot send after transport endpoint shutdown
  ESPIPE* {.importc: "UV_ESPIPE", header: "uv.h".}: cint
    ## invalid seek
  ESRCH* {.importc: "UV_ESRCH", header: "uv.h".}: cint
    ## no such process
  ETIMEDOUT* {.importc: "UV_ETIMEDOUT", header: "uv.h".}: cint
    ## connection timed out
  ETXTBSY* {.importc: "UV_ETXTBSY", header: "uv.h".}: cint
    ## text file is busy
  EXDEV* {.importc: "UV_EXDEV", header: "uv.h".}: cint
    ## cross-device link not permitted
  UNKNOWN* {.importc: "UV_UNKNOWN", header: "uv.h".}: cint
    ## unknown error
  EOF* {.importc: "UV_EOF", header: "uv.h".}: cint
    ## end of file
  ENXIO* {.importc: "UV_ENXIO", header: "uv.h".}: cint
    ## no such device or address
  EMLINK* {.importc: "UV_EMLINK", header: "uv.h".}: cint
    ## too many links
  EHOSTDOWN* {.importc: "UV_EHOSTDOWN", header: "uv.h".}: cint
    ## host is down

proc strError*(errCode: cint): cstring {.importc: "uv_strerror", header: "uv.h".}
  ## Returns the error message for the given error code. Leaks a few bytes of memory when you call it
  ## with an unknown error code.

proc errName*(errCode: cint): cstring {.importc: "uv_err_name", header: "uv.h".}
  ## Returns the error name for the given error code. Leaks a few bytes of memory when you call it
  ## with an unknown error code.

proc translateSysError*(errCode: cint): cstring {.importc: "uv_translate_sys_error", header: "uv.h".}
  ## Returns the libuv error code equivalent to the given platform dependent error code: POSIX error
  ## codes on Unix (the ones stored in errno), and Win32 error codes on Windows (those returned by
  ## `GetLastError()` or `WSAGetLastError()`).
  ##
  ## If `errCode` is already a libuv error, it is simply returned.


