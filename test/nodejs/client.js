var net = require('net')
var client = net.connect({
  port: 10000,
  host: '127.0.0.1',
  allowHalfOpen: true
})
client.on('connect', function () {
  console.log('connected to server!')
  client.write(
`POST /doc/node HTTP/1.1\r
Content-Length: 1\r
Expect: 100-continue\r
\r
a`)
})
client.setEncoding('utf-8')
client.on('data', (d)=> {
  console.log("%j", d)
})
//   client.end()
//   client.write(
// `GET /doc/node HTTP/1.1\r
// Content-Type: application/x-www-form-urlencoded\r
// Content-Length: 6\r
// Connection: keep-alive\r
// \r
// 123456`)
// })
// //   client.write(
// // `GET /doc/node HTTP/1.1\r
// // Content-Type: application/x-www-form-urlencoded\r
// // Content-Length: 6\r
// // Connection: Close\r
// // \r
// // 123456`)
//   // setTimeout(() => {
//     // console.log(client.write('abcdef'))
//     // console.log(client.write('abcdef'))
//   //   console.log(client.write('abcdef'))
//   //   console.log(client.write('abcdef'))
//   //   console.log(client.write('abcdef'))
//   //   console.log(client.write('abcdef'))
//   //   console.log(client.write('abcdef'))
//   //   console.log(client.write('abcdef'))
//   //   //client.end()
//   // }, 1000)
//   // setTimeout(() => {
//   //   console.log(client.write('123456789'))
//   //   client.end()
//   //   client = net.connect({
//   //     port: 10000,
//   //     host: '127.0.0.1',
//   //     allowHalfOpen: true
//   //   })
//   //   client.on('connect', function () {
//   //     setTimeout(() => {
//   //       console.log(client.write('001001001'))
//   //       client.end()
//   //       client = net.connect({
//   //         port: 10000,
//   //         host: '127.0.0.1',
//   //         allowHalfOpen: true
//   //       })
//   //       client.on('connect', function () {
//   //         console.log(client.write('111111111'))
//   //         client.end()
//   //         console.log("...")
//   //       })
//   //     }, 1000)
//   //   })
//   // }, 1000)
// })
// client.setEncoding('utf8')
// client.on('data', (data) => {
//   console.log(data)
// })
// client.on('error', (e) => {
//   console.log(e)
// })
// // client.on('end', () => {
// //   console.log('disconnected from server')
// //   console.log('write:', client.write('abcdef'))
// //   client.end()
// // })
// // client.on('error', (e) => {
// //   console.log('socket error:', e)
// // })
// // client.on('close', () => {
// //   console.log('socket has closed')
// // })
// // client.on('drain', () => {
// //   cosole.log('drain ..................')
// // })
// // client.on('finish', () => console.log('finish'))



// var net = require('net')
// var client = net.createConnection({
//   port: 10000,
//   host: '127.0.0.1',
//   allowHalfOpen: true
// })
// client.on('connect', function () {
//   client.write('000\r\n111\r\n')
// })
// client.setEncoding('utf8')
// client.on('data', (d) => {
//   console.log('--> data', d)
// })
// client.on('end', () => {
//   console.log('end')
// })
// client.on('error', (e) => {
//   console.log('error', e)
// })
// client.on('finish', (d) => {
//   console.log('finish')
// })
// client.on('close', () => {
//   console.log('close')
// })