// var req = require('http').request({
//   hostname: '127.0.0.1',
//   port: 10000,
//   path: '/',
//   headers: {
//     // 'Transfer-Encoding': 'chunked',
//     'Content-Length': Buffer.byteLength('hello')
//   }
// })

// req.on('response', (res) => {
//   console.log('req response')
// })

// req.write('hello')
// setTimeout(() => {
//   req.end()
  
//   var sock = require('net').connect({
//     port: 10000,
//     host: '127.0.0.1',
//     allowHalfOpen: true
//   })
//   sock.on('connect', () => {
//     sock.write(
// `GET /doc/node HTTP/1.1\r
// Content-Type: application/x-www-form-urlencoded\r
// Content-Length: 6\r
// Connection: Close\r
// \r
// 123456`)
//     sock.write(
// `GET /doc HTTP/1.1\r
// Content-Type: application/x-www-form-urlencoded\r
// Content-Length: 3\r
// Connection: Close\r
// \r
// abc`)
//     sock.write(
// `GET /doc HTTP/1.1\r
// Content-Type: application/x-www-form-urlencoded\r
// Transfer-Encoding: chunked\r
// Content-Length: 3\r
// Connection: Close\r
// \r
// 4\r
// Wiki\r
// `)
//     sock.write(
// `5\r
// pedia\r
// `)  
//     sock.write(
// `E\r
//  in\r
// \r
// chunks.\r
// `)
//     sock.write(
// `0\r
// \r
// `)
//   })
// }, 3000)

var sock = require('net').connect({
  port: 10000,
  host: '127.0.0.1',
  allowHalfOpen: true
})

sock.on('connect', () => {
  sock.write(
`GET /doc/node HTTP/1.1\r
Content-Type: application/x-www-form-urlencoded\r
Content-Length: 9\r
Connection: keep-alive\r
\r
123456`)
  
  setTimeout(() => {
    sock.write('789')
    sock.write(
`GET /doc/node HTTP/1.1\r
Content-Type: application/x-www-form-urlencoded\r
Content-Length: 9\r
Connection: keep-alive\r
\r
abcdef`)  

    setTimeout(() => {
      sock.write('ghi')
    })

  }, 3000)

})

sock.on('error', (e) => {
  console.log('error', e)
})

sock.on('close', (hasError) => {
  console.log('closed', hasError)
})