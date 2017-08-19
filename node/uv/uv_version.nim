#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for 
#    details about the copyright.

## Starting with version 1.0.0 libuv follows the `semantic versioning <http://semver.org/>`_ scheme. 
## This means that new APIs can be introduced throughout the lifetime of a major release. In this 
## section you’ll find all macros and functions that will allow you to write  or compile code 
## conditionally, in order to work with multiple libuv versions.
##
## `Version-checking macros and functions <libuv 1.10.3-dev API documentation> 
## <http://docs.libuv.org/en/v1.x/version.html>`_

var 
  VERSION_MAJOR* {.importc: "UV_VERSION_MAJOR", header: "uv.h".}: cuint
    ## libuv version’s major number.
  VERSION_MINOR* {.importc: "UV_VERSION_MINOR", header: "uv.h".}: cuint
    ## libuv version’s minor number.
  VERSION_PATCH* {.importc: "UV_VERSION_PATCH", header: "uv.h".}: cuint
    ## libuv version’s patch number.
  VERSION_IS_RELEASE* {.importc: "UV_VERSION_IS_RELEASE", header: "uv.h".}: cint
    ## Set to 1 to indicate a release version of libuv, 0 for a development snapshot.
  VERSION_SUFFIX* {.importc: "UV_VERSION_SUFFIX", header: "uv.h".}: cstring
    ## libuv version suffix. Certain development releases such as Release Candidates might have a 
    ## suffix such as “rc”.
  VERSION_HEX* {.importc: "UV_VERSION_HEX", header: "uv.h".}: cuint
    ## Returns the libuv version packed into a single integer. 8 bits are used for each component, 
    ## with the patch number stored in the 8 least significant bits. E.g. for libuv 1.2.3 this would 
    ## be 0x010203.

proc version*(): cuint {.importc: "uv_version", header: "uv.h".}
  ## Returns ``VERSION_HEX``.

proc versionString*(): cstring {.importc: "uv_version_string", header: "uv.h".}
  ## Returns the libuv version number as a string. For non-release versions the version suffix is 
  ## included.





