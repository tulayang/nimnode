
import error, http

type
  HttpBuffer* = object of RootObj
    base: string
    pageSize: int
    totalSize: int
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
  result.totalSize = pageSize
  result.base = newStringOfCap(pageSize)
  result.baseLen = 0

proc initRequestBuffer*(pageSize = 1024): RequestBuffer =
  initHttpBufferImpl

proc initResponseBuffer*(pageSize = 1024): ResponseBuffer =
  initHttpBufferImpl

proc clear0*(x: var HttpBuffer) =
  x.totalSize = x.pageSize
  x.base = newString(x.pageSize)
  x.baseLen = 0

proc clear*(x: var HttpBuffer) =
  x.totalSize = x.pageSize
  setLen(x.base, x.pageSize)
  x.baseLen = 0

proc len*(x: HttpBuffer): int = 
  result = x.baseLen

proc checkForIncrease(x: var HttpBuffer, size: int) =
  if size > x.totalSize - x.baseLen:
    x.totalSize = ((x.baseLen + size) div x.pageSize + 1) * x.pageSize  
    var base: string
    shallowCopy(base, x.base) 
    x.base = newString(x.totalSize)
    copyMem(x.base.cstring, base.cstring, x.baseLen)

proc write*(x: var HttpBuffer, buf: pointer, size: int) =
  checkForIncrease(x, size)
  copyMem(offsetChar(x.base.cstring, x.baseLen), buf, size)
  inc(x.baseLen, size)

proc write*(x: var HttpBuffer, buf: string) =
  write(x, buf.cstring, buf.len)

proc writeHead*(x: var ResponseBuffer, statusCode: int) =
  write(x, "HTTP/1.1 " & $statusCode & " OK\c\LContent-Length: 0\c\L\c\L")

proc writeHead*(x: var ResponseBuffer, statusCode: int, 
                headers: openarray[tuple[key, value: string]]) =
  write(x, "HTTP/1.1 " & $statusCode & " OK\c\L")
  for header in headers:
    write(x, header.key & ": " & header.value & "\c\L")
  write(x, "\c\L")

proc writeHead*(x: var RequestBuffer, reqMethod: string, url: string) =
  write(x, reqMethod & " " & url & " HTTP/1.1\c\L")#Content-Length: 0\c\L\c\L")

proc writeHead*(x: var RequestBuffer, reqMethod: string, url: string, 
                headers: openarray[tuple[key, value: string]]) =
  write(x, reqMethod & " " & url & " HTTP/1.1\c\L")#Content-Length: 0\c\L\c\L")
  for header in headers:
    write(x, header.key & ": " & header.value & "\c\L")
  write(x, "\c\L")

proc writeChunk*(x: var HttpBuffer, buf: pointer, size: int) =
  let chunkSize = size.toChunkSize()
  let tail = "\c\L"
  write(x, chunkSize.cstring, chunkSize.len)
  write(x, tail.cstring, 2)
  write(x, buf, size)
  write(x, tail.cstring, 2)

proc writeChunk*(x: var HttpBuffer, buf: string) =
  x.writeChunk(buf.cstring, buf.len)

proc writeChunkTail*(x: var HttpBuffer) =
  write(x, "0\c\L\c\L")

proc write*(h: HttpServerStream, buf: HttpBuffer, 
            cb: proc (err: ref NodeError) {.closure, gcsafe.} = nil) =  
  GC_ref(buf.base)
  write(h, buf.base.cstring, buf.baseLen) do (err: ref NodeError):
    GC_unref(buf.base)
    if cb != nil:
      cb(err)


      