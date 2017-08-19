import unittest, uv.misc, uv.error

suite "uv.misc":
  setup: # run before each test
    discard
  
  teardown: # run after each test
    discard
  
  test "createBuffer":
    var length = 16
    var base = cast[cstring](alloc0(16))
    var buf = createBuffer(base, cuint(length))
    var source = "123456"
    copyMem(base, cstring(source), 6)
    check(buf.base == "123456")
    check(buf.base.len == 6)
    dealloc(buf.base)

  test "setupArgs":
    var cmdCount {.importc: "cmdCount".}: cint
    var cmdLine {.importc: "cmdLine".}: cstringArray
    var storedArgv = setupArgs(cmdCount, cmdLine)
    for i in 0..cmdCount-1:
      echo "  Argv ", $i, ": ", storedArgv[i] 

  test "setProcessTitle":
    let title = "Hello world!"
    let ret = setProcessTitle(cstring(title))
    check(ret == 0)

  test "getProcessTitle":
    var s = newString(1)
    let ret = getProcessTitle(cstring(s), 1)
    check(ret == ENOBUFS)
    var s2 = newString(255)
    let ret2 = getProcessTitle(cstring(s2), len(s2))
    check(ret2 == 0)
    echo "  Process title: ", s2

  test "getResidentSetMemory":
    var rss: csize
    let ret = getResidentSetMemory(rss)
    check(ret == 0)
    echo "  Resident set memory: ", rss, " bytes"

  test "getUpTime":
    var uptime: cdouble
    let ret = getUpTime(uptime)
    check(ret == 0)
    echo "  Up time: ", uptime, " seconds"

  test "getResourceUsage":
    var rusage: ResourceUsage
    for i in 0..1000000:
      discard
    let ret = getResourceUsage(rusage)
    check(ret == 0)
    echo "  Resource usage: ", rusage

  test "getCpuInfo freeCpuInfo":
    var cpuInfos: ptr CpuInfo
    var count: cint
    let ret = getCpuInfo(cpuInfos, count)
    check(ret == 0)
    for i in 0..count-1:
      let cpuinfo = cast[ptr CpuInfo](cast[ByteAddress](cpuInfos) + i * sizeof(CpuInfo))
      echo "  CPU info: ", cpuinfo[]
    freeCpuInfo(cpuInfos, count)

  test "getInterfaceAddresses freeInterfaceAddresses":
    var addresses: ptr InterfaceAddress
    var count: cint
    let ret = getInterfaceAddresses(addresses, count)
    check(ret == 0)
    for i in 0..count-1:
      let address = cast[ptr InterfaceAddress](cast[ByteAddress](addresses) + i * sizeof(InterfaceAddress))
      echo "  Interface address: ", address[]
    freeInterfaceAddresses(addresses, count)

  test "getLoadAverage":
    var avg: array[3, cdouble]
    getLoadAverage(avg)
    echo "  Load average: ", avg[0], ", ", avg[1], ", ", avg[2]

  test "toIp4Addr toIp4Name":
    var sockAddr: SockAddrIn
    let ret = toIp4Addr("116.0.1.16", cint(8000), sockAddr)
    check(ret == 0)
    echo "  IPv4 Address: ", sockAddr
    var dst = newString(11)
    let ret2 = toIp4Name(addr(sockAddr), dst, len(dst))
    check(ret2 == 0)
    check(dst == "116.0.1.16\0")

  test "toIp6Addr toIp6Name":
    var sockAddr: SockAddrIn6
    let ret = toIp6Addr("::1", cint(8000), sockAddr)
    check(ret == 0)
    echo "  IPv4 Address: ", sockAddr
    var dst = newString(4)
    let ret2 = toIp6Name(addr(sockAddr), dst, len(dst))
    check(ret2 == 0)
    check(dst == "::1\0")

  test "inetNtop inetPton":
    let src = "127.0.0.1"
    var netIP = newString(2)
    let ret = inetPton(AF_INET, cstring(src), cstring(netIP))
    check(ret == 0)
    check(netIP == "\0")
    var preIP = newString(10)
    let ret2 = inetNtop(AF_INET, cstring(netIP), cstring(preIP), len(preIP))
    check(ret2 == 0)
    check(preIP == "127.0.0.1\0")

  test "getExePath":
    var buffer: array[255, char]
    var size: csize = 255
    let ret = getExePath(buffer, size)
    check(ret == 0)
    echo "  Executable path: ",  buffer, ", Size: ", size
    
  test "getCurrentDir":
    var buffer: array[255, char]
    var size: csize = 255
    let ret = getCurrentDir(buffer, size)
    check(ret == 0)
    echo "  Current working directory: ",  buffer, ", Size: ", size

  test "chgCurrentDir":
    let ret = chgCurrentDir("/home/king/App")
    check(ret == 0)
    var buffer = newString(15)
    var size: csize = 15
    let ret2 = getCurrentDir(buffer, size)
    check(ret == 0)
    check(buffer == "/home/king/App\0")
    check(size == 14)
  
  test "getHomeDir":
    var buffer: array[255, char]
    var size: csize = 255
    let ret = getHomeDir(buffer, size)
    check(ret == 0)
    echo "  Home directory: ",  buffer, ", Size: ", size

  test "getTpmDir":
    var buffer: array[255, char]
    var size: csize = 255
    let ret = getTpmDir(buffer, size)
    check(ret == 0)
    echo "  Temp directory: ",  buffer, ", Size: ", size
  
  test "getPassword freePassword":
    var passwd: Password
    let ret = getPassword(passwd)
    check(ret == 0)
    echo "  Passwd: ",  passwd
    freePassword(passwd)

  test "getTotalMemory":
    let ret = getTotalMemory()
    echo "  Total memory: ",  ret, " bytes"

  test "hrTime":
    let ret = hrTime()
    echo "  Hr time: ",  ret, " nanoseconds"