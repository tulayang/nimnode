#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## ``Request`` is the base type for all libuv request types.
##
## Structures are aligned so that any libuv request can be cast to ``Request``. All API functions 
## defined here work with any request type.
##
## `Base request <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/request.html>`_

type
  Request* {.pure, final, importc: "uv_req_t", header: "uv.h".} = object ## The base libuv request type.
    typ* {.importc: "type".}: RequestType ## Indicated the type of request. Readonly.
    data* {.importc: "data".}: pointer ## Space for user-defined arbitrary data. libuv does not use this field.   

  RequestType* = enum ## The kind of the libuv request.
    reqUnknown = 0, reqRequest, reqConnect, reqWrite, reqShutDown, reqUdpSend, reqFs, reqWork,
    reqGetAddrInfo, reqGetNameInfo, reqRequestTypePriavte, reqRequestTypeMax

  AnyRequest* {.pure, final, union, importc: "uv_any_req", header: "uv.h".} = object

proc cancel*(req: ptr Request): cint {.importc: "uv_cancel", header: "uv.h".}
  ## Cancel a pending request. Fails if the request is executing or has finished executing.
  ##
  ## Returns 0 on success, or an error code < 0 on failure.
  ##
  ## Only cancellation of ``Fs``, GetAddrInfo``, ``GetNameInfo`` and ``Work`` requests is currently supported.
  ##
  ## Cancelled requests have their callbacks invoked some time in the future. It’s not safe to free the 
  ## memory associated with the request until the callback is called.
  ##
  ## Here is how cancellation is reported to the callback:
  ## 
  ## - A ``Fs`` request has its req.result field set to ``ECANCELED``.
  ## - A ``Work``, ``GetAddrInfo`` or c:type:``GetNameInfo`` request has its callback invoked with status == ``ECANCELED``.

proc sizeofRequest*(typ: RequestType): csize {.importc: "uv_req_size", header: "uv.h".}
  ## Returns the size of the given request type. Useful for FFI binding writers who don’t want to know the structure layout.