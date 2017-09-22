var http = require('http')
var req1 = null
var req2 = null
var con1 = null
var con2 = null
var srv = http.createServer((req, res) => {
  // if (con1 === req.socket) {
  //   console.log('socket true')
  // } else {
  //   console.log('socket false')
  //   con1 = req.socket
  // }
  // if (req1 === req) {
  //   console.log('req true')
  // } else {
  //   console.log('req false')
  //   req1 = req
  // }
  console.log('request ...')
  req.setEncoding('utf8')
  req.on('data', (d) => {
    console.log('----------------------------------------------')
    console.log(Buffer.byteLength(d))
    var data = ""
    data += Buffer.byteLength(d) + '\n'
    data += d + '\n'
    data += '----------------------------------------------\n'
    require('fs').appendFileSync('./log', data, 'utf-8')
    // req.pause()
    // setTimeout(() => {
    //   req.resume()
    // }, 1000)
  })
  req.on('end', () => {
    console.log('data: end')
    //res.end('Hello world')
    // res.writeHead(200, {
    //   "Content-Length": 1,
    //   "Connection": "keep-alive"
    // })
    // res.write('ok\r\nHTTP 1.0 302 OK\r\n')
    // res.writeHead(302, {
    //   "Content-Length": 1
    // })

    // setTimeout(() => {
    //   res.write("abc")

    //   res.writeHead(200, {
    //     "Content-Length": 3
    //   })

    //   res.writeHead(302, {
    //     "Content-Length": 100
    //   })
    //   res.write("helloa")
    // }, 100)

    // res.writeHead(200, {
    //   "Content-Length": 3
    // })
    
    // res.write("worlda")
  })
  req.on('error', (e) => {
    console.log("req error:", e)
  })
  res.on('error', (e) => {
    console.log("res error:", e)
  })
})
srv.listen(10000)


