#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## Provides error codes corresponding the libuv errornos. 
## NimNode use these codes to indicate an internal error which caused 
## by libuv operations.

import uv.uv_error, macros

type
  NodeErrorCode* = enum ## Internal error code corresponding libuv.
    E2BIG = "argument list too long"
    EACCES = "permission denied"
    EADDRINUSE = "address already in use"
    EADDRNOTAVAIL = "address not available"
    EAFNOSUPPORT = "address family not supported"
    EAGAIN = "resource temporarily unavailable"
    EAI_ADDRFAMILY = "address family not supported"
    EAI_AGAIN = "temporary failure"
    EAI_BADFLAGS = "bad ai_flags value"
    EAI_BADHINTS = "invalid value for hints"
    EAI_CANCELED = "request canceled"
    EAI_FAIL = "permanent failure"
    EAI_FAMILY = "ai_family not supported"
    EAI_MEMORY = "out of memory"
    EAI_NODATA = "no address"
    EAI_NONAME = "unknown node or service"
    EAI_OVERFLOW = "argument buffer overflow"
    EAI_PROTOCOL = "resolved protocol is unknown"
    EAI_SERVICE = "service not available for socket type"
    EAI_SOCKTYPE = "socket type not supported"
    EALREADY = "connection already in progress"
    EBADF = "bad file descriptor"
    EBUSY = "resource busy or locked"
    ECANCELED = "operation canceled"
    ECHARSET = "invalid Unicode character"
    ECONNABORTED = "software caused connection abort"
    ECONNREFUSED = "connection refused"
    ECONNRESET = "connection reset by peer"
    EDESTADDRREQ = "destination address required"
    EEXIST = "file already exists"
    EFAULT = "bad address in system call argument"
    EFBIG = "file too large"
    EHOSTUNREACH = "host is unreachable"
    EINTR = "interrupted system call"
    EINVAL = "invalid argument"
    EIO = "i/o error"
    EISCONN = "socket is already connected"
    EISDIR = "illegal operation on a directory"
    ELOOP = "too many symbolic links encountered"
    EMFILE = "too many open files"
    EMSGSIZE = "message too long"
    ENAMETOOLONG = "name too long"
    ENETDOWN = "network is down"
    ENETUNREACH = "network is unreachable"
    ENFILE = "file table overflow"
    ENOBUFS = "no buffer space available"
    ENODEV = "no such device"
    ENOENT = "no such file or directory"
    ENOMEM = "not enough memory"
    ENONET = "machine is not on the network"
    ENOPROTOOPT = "protocol not available"
    ENOSPC = "no space left on device"
    ENOSYS = "function not implemented"
    ENOTCONN = "socket is not connected"
    ENOTDIR = "not a directory"
    ENOTEMPTY = "directory not empty"
    ENOTSOCK = "socket operation on non-socket"
    ENOTSUP = "operation not supported on socket"
    EPERM = "operation not permitted"
    EPIPE = "broken pipe"
    EPROTO = "protocol error"
    EPROTONOSUPPORT = "protocol not supported"
    EPROTOTYPE = "protocol wrong type for socket"
    ERANGE = "result too large"
    EROFS = "read-only file system"
    ESHUTDOWN = "cannot send after transport endpoint shutdown"
    ESPIPE = "invalid seek"
    ESRCH = "no such process"
    ETIMEDOUT = "connection timed out"
    ETXTBSY = "text file is busy"
    EXDEV = "cross-device link not permitted"
    UNKNOWN = "unknown error"
    EOF = "end of file"
    ENXIO = "no such device or address"
    EMLINK = "too many links"
    EHOSTDOWN = "host is down"
    UNKNOWNSYS = "unknown system error"

    ENOD_WREND = "write after end"

  NodeError* = object of Exception ## Raised if an internal operation failed.
    errorCode*: NodeErrorCode ## The ``NodeErrorCode`` value.
    #errorNo*: cint ## The value corresponding to the libuv errorno.
                    # I think we don't need it anymore.

macro defErrors(errorCodes: varargs[NodeErrorCode]): untyped =
  # I know, I know, this macro is just for fun. Got:
  #
  #   var errorLen: int = ...
  #   var errorNos: array[errorLen, cint] = ...
  #   var errorCodes: array[errorLen, NodeErrorCode] = ...
  result = newNimNode(nnkStmtList)
  var codeBracket = newNimNode(nnkBracket)
  var noBracket = newNimNode(nnkBracket)
  var i = 0
  for code in errorCodes:
    noBracket.add(
      newDotExpr(
        newIdentNode(!"uv_error"), 
        newIdentNode(!($code))))
    codeBracket.add(
      newIdentNode(!($code)))
    inc(i)
  result.add(
    newNimNode(nnkVarSection).add(
      newNimNode(nnkIdentDefs).add(
        newIdentNode(!"errorNos"),
        newNimNode(nnkBracketExpr).add(
          newIdentNode(!"array"),
          newLit(i),
          newIdentNode(!"cint")),
        noBracket)),
    newNimNode(nnkVarSection).add(
      newNimNode(nnkIdentDefs).add(
        newIdentNode(!"errorCodes"),
        newNimNode(nnkBracketExpr).add(
          newIdentNode(!"array"),
          newLit(i),
          newIdentNode(!"NodeErrorCode")),
        codeBracket)),
    newNimNode(nnkConstSection).add(
      newNimNode(nnkConstDef).add(
        newIdentNode(!"errorLen"),
        newEmptyNode(),
        newLit(i))),
    newNimNode(nnkVarSection).add(
      newNimNode(nnkIdentDefs).add(
        newIdentNode(!"errorsSorted"),
        newEmptyNode(),
        newLit(false))))

defErrors(
  E2BIG, EACCES, EADDRINUSE, EADDRNOTAVAIL, EAFNOSUPPORT, EAGAIN, EAI_ADDRFAMILY, 
  EAI_AGAIN, EAI_BADFLAGS, EAI_BADHINTS, EAI_CANCELED, EAI_FAIL, EAI_FAMILY, 
  EAI_MEMORY, EAI_NODATA, EAI_NONAME, EAI_OVERFLOW, EAI_PROTOCOL, EAI_SERVICE, 
  EAI_SOCKTYPE, EALREADY, EBADF, EBUSY, ECANCELED, ECHARSET, ECONNABORTED, 
  ECONNREFUSED, ECONNRESET, EDESTADDRREQ, EEXIST, EFAULT, EFBIG, EHOSTUNREACH, 
  EINTR, EINVAL, EIO, EISCONN, EISDIR, ELOOP, EMFILE, EMSGSIZE, ENAMETOOLONG, 
  ENETDOWN, ENETUNREACH, ENFILE, ENOBUFS, ENODEV, ENOENT, ENOMEM, ENONET, 
  ENOPROTOOPT, ENOSPC, ENOSYS, ENOTCONN, ENOTDIR, ENOTEMPTY, ENOTSOCK, ENOTSUP, 
  EPERM, EPIPE, EPROTO, EPROTONOSUPPORT, EPROTOTYPE, ERANGE, EROFS, ESHUTDOWN, 
  ESPIPE, ESRCH, ETIMEDOUT, ETXTBSY, EXDEV, UNKNOWN, EOF, ENXIO, EMLINK, EHOSTDOWN)

proc orderSort(codeArr, codeTmpArr: var openarray[NodeErrorCode];
               noArr, noTmpArr: var openarray[cint];
               arrLen: int; start: int; n: int) =
  var mid = start + n div 2
  var orderLen = start + n
  var i = start
  var j = mid
  var size = 0
  while true:
    if i >= arrLen or j >= arrLen or i >= mid or j >= orderLen:
      break
    if noArr[i] <= noArr[j]:
      noTmpArr[size] = noArr[i]
      codeTmpArr[size] = codeArr[i]
      inc(size)
      inc(i)
    else:
      noTmpArr[size] = noArr[j]
      codeTmpArr[size] = codeArr[j]
      inc(size)
      inc(j)
  while true:
    if i >= arrLen or i >= mid:
      break
    noTmpArr[size] = noArr[i]
    codeTmpArr[size] = codeArr[i]
    inc(size)
    inc(i)
  while true:
    if j >= arrLen or j >= orderLen:
      break
    noTmpArr[size] = noArr[j]
    codeTmpArr[size] = codeArr[j]
    inc(size)
    inc(j)
  copyMem(addr(noArr[start]), addr(noTmpArr[0]), size * sizeof(cint))
  copyMem(addr(codeArr[start]), addr(codeTmpArr[0]), size * sizeof(NodeErrorCode))

proc mergeSort(codeArr: var openarray[NodeErrorCode], 
               noArr: var openarray[cint], arrLen: int) = 
  var codeTmpArr = newSeq[NodeErrorCode](arrLen)
  var noTmpArr = newSeq[cint](arrLen)
  var n = 2
  while n <= arrLen or n div 2 < arrLen:
    var i = 0
    while i < arrLen:
      orderSort(codeArr, codeTmpArr, noArr, noTmpArr, arrLen, i, n)
      inc(i, n)
    n = n * 2

proc binarySearch(arr: var openarray[cint], arrLen: int, x: cint): int =
  var left = 0
  var right = arrLen - 1
  var i = left + (right - left) div 2
  while true:
    if arr[i] == x:
      return i
    elif arr[i] > x:
      if i == left:
        return -1
      right = i
      i = left + (right - left) div 2
    else:
      if i == right:
        return -1
      left = i
      i = left + (right - left) div 2
      if i == left:
        i = right

proc newNodeError*(errorCode: cint): ref NodeError =
  ## Creates a new error caused by libuv operation. ``errorCode`` should be a 
  ## libuv errorno.
  new(result)
  if not errorsSorted:
    mergeSort(errorCodes, errorNos, errorLen)
    errorsSorted = true
  let i = binarySearch(errorNos, errorLen, errorCode)
  if i < 0:
    result.errorCode = UNKNOWNSYS
    result.msg = $UNKNOWNSYS & " " & $errorCode
  else:
    result.errorCode = errorCodes[i]
    result.msg = $errorCodes[i]

proc newNodeError*(errorCode: NodeErrorCode): ref NodeError =
  ## Creates a new error caused by libuv operation. 
  new(result)
  result.errorCode = errorCode
  result.msg = $errorCode

