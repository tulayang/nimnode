#    NimNode - Library for async programming and communication
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

## 这个模块实现了几个 Buffer，用来高效地传输 HTTP 数据。他们是纯粹的数据缓冲，不参与 IO。
## 配合 net 和 http 模块，你可以以流的方式发送大量的数据。
## 
## HttpBuffer 有两种方式，请求或者响应，分别对应不同的 HTTP 传输。

import error, http

type
  HttpBuffer* = object of RootObj ## HTTP buffer object.
    base: string
    pageSize: int
    realSize: int
    baseLen: int
  RequestBuffer* = object of HttpBuffer
  ResponseBuffer* = object of HttpBuffer

template offsetChar(x: pointer, i: int): pointer =
  cast[pointer](cast[ByteAddress](x) + i * sizeof(char))

proc toChunkSize(x: BiggestInt): string =
  assert x >= 0
  const HexChars = "0123456789ABCDEF"
  var n = x
  var m = 0
  var s = newString(5) # sizeof(BiggestInt) * 10 / 16
  for j in countdown(4, 0):
    s[j] = HexChars[n and 0xF]
    n = n shr 4
    inc(m)
    if n == 0: 
      break
  result = newStringOfCap(m)
  for i in 5-m..<5:
    add(result, s[i])

template initHttpBufferImpl() {.dirty.} =
  result.pageSize = pageSize
  result.realSize = pageSize
  result.base = newStringOfCap(pageSize)
  result.baseLen = 0

proc initRequestBuffer*(pageSize = 1024): RequestBuffer =
  ## Initializes a ``RequestBuffer`` for HTTP request. ``pageSize`` is the base unit for storage.
  ## 当写入的数据超过当前的容量时，``RequestBuffer`` 基于 ``pageSize`` 增长，直到可以容纳当前的数据。
  initHttpBufferImpl

proc initResponseBuffer*(pageSize = 1024): ResponseBuffer =
  ## Initializes a ``ResponseBuffer`` for HTTP response. ``pageSize`` is the base unit for storage.
  ## 当写入的数据超过当前的容量时，``ResponseBuffer`` 基于 ``pageSize`` 增长，直到可以容纳当前的数据。
  initHttpBufferImpl

proc clear0*(x: var HttpBuffer) =
  ## Clears ``x``, the internal storage reallocates memory space.
  x.realSize = x.pageSize
  x.base = newString(x.pageSize)
  x.baseLen = 0

proc clear*(x: var HttpBuffer) =
  ## Clears ``x``, the internal storage cleares to zeros. This method is more efficient,
  ## but the length of the storage space remains unchanged.
  x.realSize = x.pageSize
  setLen(x.base, x.pageSize)
  x.baseLen = 0

proc len*(x: HttpBuffer): int = 
  ## 返回存储数据的实际长度
  result = x.baseLen

proc expandIfNeeded(x: var HttpBuffer, size: int) =
  if size > x.realSize - x.baseLen:
    x.realSize = ((x.baseLen + size) div x.pageSize + 1) * x.pageSize  
    var base: string
    shallowCopy(base, x.base) 
    x.base = newString(x.realSize)
    copyMem(x.base.cstring, base.cstring, x.baseLen)

proc write*(x: var HttpBuffer, buf: pointer, size: int) =
  ## 写入一块数据，这个数据可以是任意格式的。``buf`` 表示数据缓冲的地址，``size`` 表示数据缓冲的长度。
  expandIfNeeded(x, size)
  copyMem(offsetChar(x.base.cstring, x.baseLen), buf, size)
  inc(x.baseLen, size)

proc write*(x: var HttpBuffer, buf: string) =
  ## 写入一块数据，这个数据可以是任意格式的。``buf`` 表示要写入的数据。
  write(x, buf.cstring, buf.len)

proc writeChunk*(x: var HttpBuffer, buf: pointer, size: int) =
  ## 写入一块基于 chunked 编码的数据。``buf`` 表示数据缓冲的地址，``size`` 表示数据缓冲的长度。
  ## 通常，在基于 chunked HTTP 传输的时候，你会需要这个过程。
  let chunkSize = size.toChunkSize()
  let tail = "\c\L"
  write(x, chunkSize.cstring, chunkSize.len)
  write(x, tail.cstring, 2)
  write(x, buf, size)
  write(x, tail.cstring, 2)

proc writeChunk*(x: var HttpBuffer, buf: string) =
  ## 写入一块基于 chunked 编码的数据。``buf`` 表示数据缓冲的地址，``size`` 表示数据缓冲的长度。
  ## 通常，在基于 chunked HTTP 传输的时候，你会需要这个过程。
  x.writeChunk(buf.cstring, buf.len)

proc writeChunkTail*(x: var HttpBuffer) =
  ## 写入一块基于 chunked 编码的数据的结尾。``buf`` 表示数据缓冲的地址，``size`` 表示数据缓冲的长度。
  ## 通常，在基于 chunked HTTP 传输的时候，你会需要这个过程。
  ## 
  ## 这个过程仅仅用在 chunked 结尾。
  write(x, "0\c\L\c\L")

proc writeHead*(x: var ResponseBuffer, statusCode: int) =
  ## 写入一块 HTTP 响应头。``statusCode` 表示状态码，响应头的内容是空的。
  write(x, "HTTP/1.1 " & $statusCode & " OK\c\LContent-Length: 0\c\L\c\L")

proc writeHead*(x: var ResponseBuffer, statusCode: int, 
                headers: openarray[tuple[key, value: string]]) =
  ## 写入一块 HTTP 响应头。``statusCode` 表示状态码，``headers`` 响应请求头的内容。
  write(x, "HTTP/1.1 " & $statusCode & " OK\c\L")
  for header in headers:
    write(x, header.key & ": " & header.value & "\c\L")
  write(x, "\c\L")

proc writeHead*(x: var RequestBuffer, reqMethod: string, url: string) =
  ## 写入一块 HTTP 请求头。``reqMethod` 表示请求方法，``url`` 表示请求资源 URI， 请求头的内容是空的。
  write(x, reqMethod & " " & url & " HTTP/1.1\c\L")#Content-Length: 0\c\L\c\L")

proc writeHead*(x: var RequestBuffer, reqMethod: string, url: string, 
                headers: openarray[tuple[key, value: string]]) =
  ## 写入一块 HTTP 请求头。``reqMethod` 表示请求方法，``url`` 表示请求资源 URI，``headers`` 表示请求头的内容。
  write(x, reqMethod & " " & url & " HTTP/1.1\c\L")#Content-Length: 0\c\L\c\L")
  for header in headers:
    write(x, header.key & ": " & header.value & "\c\L")
  write(x, "\c\L")

proc write*(h: HttpServerStream, buf: HttpBuffer, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =  
  ## 使用 ``h`` 发送 ``buf`` 存储的数据，发送完成或者出现错误的时候，调用 ``cb``。
  ## 
  ## 这个过程是 HTTP 传输的常用过程，可以大幅度简化处理 HTTP 传输。
  GC_ref(buf.base)
  write(h, buf.base.cstring, buf.baseLen) do (err: ref NodeError):
    GC_unref(buf.base)
    if cb != nil:
      cb(err)


      