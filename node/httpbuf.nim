type
  HttpBuffer* = object of RootObj
    base*: string
    initialSize: int
    size: int
    length*: int
  RequestBuffer* = object of HttpBuffer
  ResponseBuffer* = object of HttpBuffer

template offsetChar(x: pointer, i: int): pointer =
  cast[pointer](cast[ByteAddress](x) + i * sizeof(char))

proc toChunkSize*(x: BiggestInt): string =
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
  result.initialSize = initialSize
  result.size = initialSize
  result.base = newString(initialSize)
  result.length = 0

proc initRequestBuffer*(initialSize = 1024): RequestBuffer =
  initHttpBufferImpl

proc initResponseBuffer*(initialSize = 1024): ResponseBuffer =
  initHttpBufferImpl

proc increase(x: var HttpBuffer, size: int) =
  let size = x.size
  x.size = x.size * 2
  while size > x.size - x.length:
    x.size = x.size * 2
  var base: string
  shallowCopy(base, x.base) 
  x.base = newString(x.size)
  copyMem(x.base.cstring, base.cstring, size)

proc write*(x: var HttpBuffer, buf: pointer, size: int) =
  if size > x.size - x.length:
    x.increase(size)
  copyMem(offsetChar(x.base.cstring, x.length), buf, size)
  x.length.inc(size)

proc write*(x: var HttpBuffer, buf: string) =
  x.write(buf.cstring, buf.len)

proc writeLine*(x: var HttpBuffer, buf: pointer, size: int) =
  let totalSize = size + 2
  if totalSize > x.size - x.length:
    x.increase(totalSize)
  copyMem(offsetChar(x.base.cstring, x.length), buf, size)
  x.length.inc(size)
  var tail = ['\c', '\L']
  copyMem(offsetChar(x.base.cstring, x.length), tail[0].addr, 2)
  x.length.inc(2)

proc writeLine*(x: var HttpBuffer, buf: string) = 
  x.writeLine(buf.cstring, buf.len)

proc writeChunk*(x: var HttpBuffer, buf: pointer, size: int) =
  let chunkSize = size.toChunkSize()
  let chunkSizeLen = chunkSize.len()
  let totalSize = chunkSizeLen + 2 + size + 2
  if totalSize > x.size - x.length:
    x.increase(totalSize)
  var tail = ['\c', '\L']
  copyMem(offsetChar(x.base.cstring, x.length), chunkSize.cstring, chunkSizeLen)
  x.length.inc(chunkSizeLen)
  copyMem(offsetChar(x.base.cstring, x.length), tail[0].addr, 2)
  x.length.inc(2)
  copyMem(offsetChar(x.base.cstring, x.length), buf, size)
  x.length.inc(size)
  copyMem(offsetChar(x.base.cstring, x.length), tail[0].addr, 2)
  x.length.inc(2)

proc writeChunk*(x: var HttpBuffer, buf: string) =
  x.writeChunk(buf.cstring, buf.len)

proc writeChunkTail*(x: var HttpBuffer) =
  if 5 > x.size - x.length:
    x.increase(5)
  var tail = ['0', '\c', '\L', '\c', '\L']
  copyMem(offsetChar(x.base.cstring, x.length), tail[0].addr, 5)
  x.length.inc(5)

proc writeHead*(x: var ResponseBuffer, statusCode: int) =
  x.write("HTTP/1.1 " & $statusCode & " OK\c\LContent-Length: 0\c\L\c\L")

proc writeHead*(x: var ResponseBuffer, statusCode: int, 
                headers: openarray[tuple[key, value: string]]) =
  x.write("HTTP/1.1 " & $statusCode & " OK\c\L")
  for it in headers:
    x.write(it.key & ": " & it.value & "\c\L")
  x.write("\c\L")

proc writeHead*(x: var RequestBuffer, reqMethod: string, url: string) =
  x.write(reqMethod & " " & url & " HTTP/1.1\c\L")#Content-Length: 0\c\L\c\L")

proc writeHead*(x: var RequestBuffer, reqMethod: string, url: string, 
                headers: openarray[tuple[key, value: string]]) =
  x.write(reqMethod & " " & url & " HTTP/1.1\c\L")#Content-Length: 0\c\L\c\L")
  for it in headers:
    x.write(it.key & ": " & it.value & "\c\L")
  x.write("\c\L")

proc clear0*(x: var HttpBuffer) =
  x.size = x.initialSize
  x.base = newString(x.initialSize)
  x.length = 0

proc clear*(x: var HttpBuffer) =
  x.size = x.initialSize
  x.base.setLen(x.initialSize)
  x.length = 0

proc shallowCopyBase*(x: var HttpBuffer, y: var string) =
  shallowCopy(y, x.base)

proc len*(x: HttpBuffer): int = 
  result = x.length