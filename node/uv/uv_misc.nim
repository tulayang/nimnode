#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## This section contains miscellaneous functions that don’t really belong in any other section.
##
## `Miscellaneous utilities <libuv 1.10.3-dev API documentation>
## <http://docs.libuv.org/en/v1.x/misc.html>`_

when defined(windows):
  import winlean
  export SockAddrIn, SockAddrIn6, SockAddr, AddrInfo

  type
    Buffer* {.pure, final, importc: "uv_buf_t", header: "uv.h".} = object ## Buffer data type.
      length* {.importc: "len".}: ULONG   ## Total bytes in the buffer.
      base* {.importc: "base".}: pointer  ## Pointer to the base of the buffer.
    FileHandle* = cint ## Cross platform representation of a file handle.
    SocketHandle* = winlean.SocketHandle ## Cross platform representation of a socket handle.
    FD* = winlean.Handle ## Abstract representation of a file descriptor.
    cssize* = int ## This is the same as the type ``ssize_t`` in C.
else:
  import posix
  export SockAddrIn, SockAddrIn6, SockAddr, AddrInfo

  type
    Buffer* {.pure, final, importc: "uv_buf_t", header: "uv.h".} = object ## Buffer data type.
      base* {.importc: "base".}: pointer ## Pointer to the base of the buffer.
      length* {.importc: "len".}: csize  ## Total bytes in the buffer.
    FileHandle* = cint ## Cross platform representation of a file handle.
    SocketHandle* = posix.SocketHandle ## Cross platform representation of a socket handle.
    FD* = cint ## Abstract representation of a file descriptor.
    cssize* = int ## This is the same as the type ``ssize_t`` in C.
type
  MallocProc* = proc(size: csize): pointer {.cdecl.}
    ## Replacement function for `malloc(3) <http://linux.die.net/man/3/malloc>`_.
    ## See ``replaceAllocator()``.

  ReallocProc* = proc(p: pointer, size: csize): pointer {.cdecl.}
    ## Replacement function for `realloc(3) <http://linux.die.net/man/3/realloc>`_.
    ## See ``replaceAllocator()``.

  CallocProc* = proc(count: csize, size: csize): pointer {.cdecl.}
    ## Replacement function for `calloc(3) <http://linux.die.net/man/3/calloc>`_.
    ## See ``replaceAllocator()``.

  FreeProc* = proc(p: pointer) {.cdecl.}
    ## Replacement function for `free(3) <http://linux.die.net/man/3/free>`_.
    ## See ``replaceAllocator()``.

  TimeVal* {.pure, final, importc: "uv_timeval_t", header: "uv.h".} = object
    second* {.importc: "tv_sec".}: clong
    usecond* {.importc: "tv_usec".}: clong

  ResourceUsage* {.pure, final, importc: "uv_rusage_t", header: "uv.h".} = object
    ## Data type for resource usage results.
    ##
    ## Members marked with (X) are unsupported on Windows. See
    ## `getrusage(2) <http://linux.die.net/man/2/getrusage>`_ for supported fields on Unix.
    utime* {.importc: "ru_utime".}: TimeVal      ## user CPU time used
    stime* {.importc: "ru_stime".}: TimeVal      ## system CPU time used
    maxrss* {.importc: "ru_maxrss".}: uint64     ## maximum resident set size
    ixrss* {.importc: "ru_ixrss".}: uint64       ## integral shared memory size (X)
    idrss* {.importc: "ru_idrss".}: uint64       ## integral unshared data size (X)
    isrss* {.importc: "ru_isrss".}: uint64       ## integral unshared stack size (X)
    minflt* {.importc: "ru_minflt".}: uint64     ## page reclaims (soft page faults) (X)
    majflt* {.importc: "ru_majflt".}: uint64     ## page faults (hard page faults) (X)
    nswap* {.importc: "ru_nswap".}: uint64       ## swaps (X)
    inblock* {.importc: "ru_inblock".}: uint64   ## block input operations
    oublock* {.importc: "ru_oublock".}: uint64   ## block output operations
    msgsnd* {.importc: "ru_msgsnd".}: uint64     ## IPC messages sent (X)
    msgrcv* {.importc: "ru_msgrcv".}: uint64     ## IPC messages received (X)
    nsignals* {.importc: "ru_nsignals".}: uint64 ## signals received (X)
    nvcsw* {.importc: "ru_nvcsw".}: uint64       ## voluntary context switches (X)
    nivcsw* {.importc: "ru_nivcsw".}: uint64     ## involuntary context switches (X)

  CpuTimes* = object
    user*: uint64
    nice*: uint64
    sys*: uint64
    idle*: uint64
    irq*: uint64

  CpuInfo* {.pure, final, importc: "uv_cpu_info_t", header: "uv.h".} = object
    ## Data type for CPU information.
    model*: cstring
    speed*: cint
    cpuTimes* {.importc: "cpu_times".}: CpuTimes

  SockAddrN* = object {.union.}
    address4* {.importc: "address4".}: SockAddrIn
    address6* {.importc: "address6".}: SockAddrIn6

  InterfaceAddress* {.pure, final, importc: "uv_interface_address_t", header: "uv.h".} = object
    ## Data type for interface addresses.
    name* {.importc: "name".}: cstring
    physAddr* {.importc: "phys_addr".}: array[6, char]
    isInternal* {.importc: "is_internal".}: cint
    address* {.importc: "address".}: SockAddrN
    netmask* {.importc: "netmask".}: SockAddrN

  Password* {.pure, final, importc: "uv_passwd_t", header: "uv.h".} = object
    ## Data type for password file information.
    username*: cstring
    uid*: clong
    gid*: clong
    shell*: cstring
    homedir*: cstring

proc replaceAllocator*(malloc: MallocProc, realloc: ReallocProc, calloc: CallocProc, free: FreeProc): cint {.
  importc: "uv_replace_allocator", header: "uv.h".}
  ## *New in version 1.6.0.*
  ##
  ## Override the use of the standard library’s
  ## `malloc(3) <http://linux.die.net/man/3/malloc>`_,
  ## `calloc(3) <http://linux.die.net/man/3/calloc>`_,
  ## `realloc(3) <http://linux.die.net/man/3/realloc>`_,
  ## `free(3) <http://linux.die.net/man/3/free>`_,
  ## memory allocation functions.
  ##
  ## This function must be called before any other libuv function is called or after all resources
  ## have been freed and thus libuv doesn’t reference any allocated memory chunk.
  ##
  ## On success, it returns ``0``, if any of the function pointers is ``nil`` it returns ``EINVAL``.
  ##
  ##   Warning: There is no protection against changing the allocator multiple times. If the
  ##   user changes it they are responsible for making sure the allocator is changed while no
  ##   memory was allocated with the previous allocator, or that they are compatible.

proc initBuffer*(base: pointer, length: cuint): Buffer {.importc: "uv_buf_init", header: "uv.h".}
  ## Constructor for ``Buffer``.
  ##
  ## Due to platform differences the user cannot rely on the ordering of the base and len members of
  ## the ``Buffer`` struct. The user is responsible for freeing base after the ``Buffer`` is done.
  ## Return struct passed by value.

proc setupArgs*(argc: cint, argv: cstringArray): cstringArray {.importc: "uv_setup_args", header: "uv.h".}
  ## Store the program arguments. Required for getting / setting the process title.

proc getProcessTitle*(buffer: cstring, size: csize): cint {.importc: "uv_get_process_title", header: "uv.h".}
  ## Gets the title of the current process. If buffer is ``nil`` or size is zero, ``EINVAL`` is returned.
  ## If size cannot accommodate the process title and terminating NULL character, the function returns ``ENOBUFS``.

proc setProcessTitle*(title: cstring): cint {.importc: "uv_set_process_title", header: "uv.h".}
  ## Sets the current process title.

proc getResidentSetMemory*(rss: var csize): cint {.importc: "uv_resident_set_memory", header: "uv.h".}
  ## Gets the resident set size (RSS) for the current process.

proc getUpTime*(uptime: var cdouble): cint {.importc: "uv_uptime", header: "uv.h".}
  ## Gets the current system uptime.

proc getResourceUsage*(rusage: var ResourceUsage): cint {.importc: "uv_getrusage", header: "uv.h".}
  ## Gets the resource usage measures for the current process.
  ##
  ##   Note: On Windows not all fields are set, the unsupported fields are filled with zeroes.
  ##   See ``ResourceUsage`` for more details.

proc getCpuInfo*(cpuInfos: var ptr CpuInfo, count: var cint): cint {.importc: "uv_cpu_info", header: "uv.h".}
  ## Gets information about the CPUs on the system. The cpuInfos array will have count elements and
  ## needs to be freed with ``freeCpuInfo()``.

proc freeCpuInfo*(cpuInfos: ptr CpuInfo, count: cint) {.importc: "uv_free_cpu_info", header: "uv.h".}
  ## Frees the cpu_infos array previously allocated with ``getCpuInfo()``.

proc getInterfaceAddresses*(addresses: var ptr InterfaceAddress, count: var cint): cint {.
  importc: "uv_interface_addresses", header: "uv.h".}
  ## Gets address information about the network interfaces on the system. An array of count elements
  ## is allocated and returned in addresses. It must be freed by the user , calling ``freeInterfaceAddresses()``.

proc freeInterfaceAddresses*(addresses: ptr InterfaceAddress, count: cint) {.
  importc: "uv_free_interface_addresses", header: "uv.h".}
  ## Free an array of ``InterfaceAddress`` which was returned by ``getInterfaceAddresses()``.

proc getLoadAverage*(avg: var array[3, cdouble]) {.importc: "uv_loadavg", header: "uv.h".}
  ## Gets the load average. See: http://en.wikipedia.org/wiki/Load_(computing)
  ##
  ##   Note: Returns [0,0,0] on Windows (i.e., it’s not implemented).

proc toIp4Addr*(ip: cstring, port: cint, sockAddr: var SockAddrIn): cint {.
  importc: "uv_ip4_addr", header: "uv.h".}
  ## Convert a string containing an IPv4 addresses to a binary structure.

proc toIp6Addr*(ip: cstring, port: cint, sockAddr: var SockAddrIn6): cint {.
  importc: "uv_ip6_addr", header: "uv.h".}
  ## Convert a string containing an IPv6 addresses to a binary structure.

proc toIp4Name*(src: ptr SockAddrIn, dst: cstring, size: csize): cint {.
  importc: "uv_ip4_name", header: "uv.h".}
  ## Convert a binary structure containing an IPv4 address to a string.

proc toIp6Name*(src: ptr SockAddrIn6, dst: cstring, size: csize): cint {.
  importc: "uv_ip6_name", header: "uv.h".}
  ## Convert a binary structure containing an IPv6 address to a string.

proc inetNtop*(af: cint, src: pointer, dst: cstring, size: csize): cint {.
  importc: "uv_inet_ntop", header: "uv.h".}
  ## This function converts an Internet address (either IPv4 or IPv6) from network (binary) to presentation (textual) form.
  ## `af` should be either ``AF_INET`` or ``AF_INET6``, as appropriate for the type of address being converted.

proc inetPton*(af: cint, src: cstring, dst: pointer): cint {.importc: "uv_inet_pton", header: "uv.h".}
  ## This function converts an Internet address (either IPv4 or IPv6) from presentation (textual) to network (binary) format.
  ##
  ## Cross-platform IPv6-capable implementation of `inet_ntop(3) <http://linux.die.net/man/3/inet_ntop>`_
  ## and `inet_pton(3) <http://linux.die.net/man/3/inet_pton>`_. On success they return 0. In case
  ## of error the target dst pointer is unmodified.

proc getExePath*(buffer: cstring, size: var csize): cint {.importc: "uv_exepath", header: "uv.h".}
  ## Gets the executable path.

proc getCurrentDir*(buffer: cstring, size: var csize): cint {.importc: "uv_cwd", header: "uv.h".}
  ## Gets the current working directory.
  ##
  ## Changed in version 1.1.0: On Unix the path no longer ends in a slash.

proc chgCurrentDir*(dir: cstring): cint {.importc: "uv_chdir", header: "uv.h".}
  ## Changes the current working directory.

proc getHomeDir*(buffer: cstring, size: var csize): cint {.importc: "uv_os_homedir", header: "uv.h".}
  ## Gets the current user’s home directory. On Windows, getHomeDir() first checks the ``USERPROFILE``
  ## environment variable using ``GetEnvironmentVariableW()``.
  ## If ``USERPROFILE`` is not set, ``GetUserProfileDirectoryW()`` is called. On all other operating systems,
  ## getHomeDir() first checks the HOME environment variable using `getenv(3) <http://linux.die.net/man/3/getenv>`_.
  ## If HOME is not set, `getpwuid_r(3) <http://linux.die.net/man/3/getpwuid_r>`_ is called. The user’s
  ## home directory is stored in buffer. When getHomeDir() is called, size indicates the maximum size
  ## of buffer. On success size is set to the string length of buffer. On ``ENOBUFS`` failure size is
  ## set to the required length for buffer, including the null byte.
  ##
  ##   Warning: getHomeDir() is not thread safe.
  ##
  ## *New in version 1.6.0.*

proc getTpmDir*(buffer: cstring, size: var csize): cint {.importc: "uv_os_tmpdir", header: "uv.h".}
  ## Gets the temp directory. On Windows, getTpmDir() uses GetTempPathW(). On all other operating systems,
  ## getTpmDir() uses the first environment variable found in the ordered list TMPDIR, TMP, TEMP, and TEMPDIR.
  ## If none of these are found, the path “/tmp” is used, or, on Android, “/data/local/tmp” is used. The temp
  ## directory is stored in buffer. When getTpmDir() is called, size indicates the maximum size of buffer. On
  ## success size is set to the string length of buffer (which does not include the terminating null). On
  ## ``ENOBUFS`` failure size is set to the required length for buffer, including the null byte.
  ##
  ##   Warning: getTpmDir() is not thread safe.
  ##
  ## *New in version 1.6.0.*

proc getPassword*(pwd: var Password): cint {.importc: "uv_os_get_passwd", header: "uv.h".}
  ## Gets a subset of the password file entry for the current effective uid (not the real uid). The populated
  ## data includes the username, euid, gid, shell, and home directory. On non-Windows systems, all data comes
  ## from `getpwuid_r(3) <http://linux.die.net/man/3/getpwuid_r>`_. On Windows, uid and gid are set to -1 and
  ## have no meaning, and shell is nil. After successfully calling this function, the memory allocated to pwd
  ## needs to be freed with ``freePassword()``.
  ##
  ## *New in version 1.9.0.*

proc freePassword*(pwd: var Password) {.importc: "uv_os_free_passwd", header: "uv.h".}
  ## Frees the pwd memory previously allocated with ``getPassword()``.
  ##
  ## *New in version 1.9.0.*

proc getTotalMemory*(): uint64 {.importc: "uv_get_total_memory", header: "uv.h".}
  ## Gets memory information (in bytes).

proc hrTime*(): uint64 {.importc: "uv_hrtime", header: "uv.h".}
  ## Returns the current high-resolution real time. This is expressed in nanoseconds. It is
  ## relative to an arbitrary time in the past. It is not related to the time of day and therefore not subject
  ## to clock drift. The primary use is for measuring performance between intervals.
  ##
  ##   Note: Not every platform can support nanosecond resolution; however, this value will always be in
  ##   nanoseconds.

