#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## libuv provides asynchronous variants of getaddrinfo and getnameinfo. 
##
## `DNS utility functions <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/dns.html>`_
##
##   See also The ``Request`` API functions also apply.

import uv_loop, uv_request, uv_misc

const
  NI_MAXHOST* = 1025
  NI_MAXSERV* = 32

type
  GetAddrInfo* {.pure, final, importc: "uv_getaddrinfo_t", header: "uv.h".} = object ## `getaddrinfo` request type.
    typ* {.importc: "type".}: RequestType ## Indicated the type of request. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
    loop* {.importc: "loop".}: ptr Loop ## Loop that started this getaddrinfo request and where completion will be reported. Readonly.
    addrInfo* {.importc: "addrinfo".}: ptr AddrInfo ## Pointer to a struct addrinfo containing the result. Must be freed by the user with ``freeAddrInfo()``.

  GetAddrInfoCb* = proc(req: ptr GetAddrInfo, status: cint, res: ptr AddrInfo) {.cdecl.}
    ## Callback which will be called with the getaddrinfo request result once complete. In case it was cancelled, status will have a value of ECANCELED.

  GetNameInfo* {.pure, final, importc: "uv_getnameinfo_t", header: "uv.h".} = object ## `getnameinfo` request type.
    typ* {.importc: "type".}: RequestType ## Indicated the type of request. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.
    loop* {.importc: "loop".}: ptr Loop ## Loop that started this getnameinfo request and where completion will be reported. Readonly.
    addrInfo* {.importc: "addrinfo".}: ptr AddrInfo ## Pointer to a struct addrinfo containing the result. Must be freed by the user with ``freeAddrInfo()``.
    host* {.importc: "host".}: array[NI_MAXHOST, char] ## Char array containing the resulting host. It’s null terminated.
    service* {.importc: "service".}: array[NI_MAXSERV, char] ## Char array containing the resulting service. It’s null terminated.

  GetNameInfoCb* = proc(req: ptr GetNameInfo, status: cint, hostname: cstring, service: cstring) {.cdecl.}
    ## Callback which will be called with the getaddrinfo request result once complete. In case it was cancelled, status will have a value of ECANCELED.

proc getAddrInfo*(loop: ptr Loop, req: ptr GetAddrInfo, cb: GetAddrInfoCb, node: cstring, service: cstring, hints: ptr AddrInfo): cint {.importc: "uv_getaddrinfo", header: "uv.h".}
  ## Asynchronous `getaddrinfo(3) <http://linux.die.net/man/3/getaddrinfo>`_.
  ##
  ## Either node or service may be nil but not both.
  ##
  ## `hints` is a pointer to a struct addrinfo with additional address type constraints, or nil. Consult `man -s 3 getaddrinfo` for more details.
  ##
  ## Returns 0 on success or an error code < 0 on failure. If successful, the callback will get called sometime in the future with the lookup result, which is either:
  ##
  ## - status == 0, the res argument points to a valid struct addrinfo, or
  ## - status < 0, the res argument is nil. See the EAI_* constants.
  ##
  ## Call ``freeAddrInfo()`` to free the addrinfo structure.
  ##
  ## Changed in version 1.3.0: the callback parameter is now allowed to be nil, in which case the request will run synchronously.

proc freeAddrInfo*(ai: ptr AddrInfo) {.importc: "uv_freeaddrinfo", header: "uv.h".}
  ## Free the struct addrinfo. Passing nil is allowed and is a no-op.
  
proc getNameInfo*(loop: ptr Loop, req: ptr GetNameInfo, cb: GetNameInfoCb, sockAddr: ptr SockAddr, flags: cint): cint {.importc: "uv_getnameinfo", header: "uv.h".}
  ## Asynchronous `getnameinfo(3) <http://linux.die.net/man/3/getnameinfo>`_.
  ##
  ## Returns 0 on success or an error code < 0 on failure. If successful, the callback will get called sometime in the future with the lookup result. Consult man -s 3 getnameinfo for more details.
  ##
  ## Changed in version 1.3.0: the callback parameter is now allowed to be nil, in which case the request will run synchronously.