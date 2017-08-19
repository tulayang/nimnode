#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## Provides an asynchronous network wrapper. It contains functions for creating 
## both servers and clients (called streams). 

import nativesockets

type
  Port* = distinct uint16 ## Port type.

  Domain* = enum
    ## specifies the protocol family of the created socket. Other domains than
    ## those that are listed here are unsupported.
    AF_UNIX,             ## for local socket (using a file). Unsupported on Windows.
    AF_INET = 2,         ## for network protocol IPv4 or
    AF_INET6 = 23        ## for network protocol IPv6.

  KeepAliveDelay* = distinct cuint