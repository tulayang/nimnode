//var keepAliveAgent = new require('http').Agent({ keepAlive: true });
//require('http').globalAgent.keepAlive = true
// require('http').globalAgent.maxSockets = 1
var keepAliveAgent = new require('http').Agent({ keepAlive: true, maxSockets: 1, maxFreeSockets: 1 })
// keepAliveAgent.maxSockets = 1
// keepAliveAgent.maxFreeSockets = 1
// console.log(keepAliveAgent.sockets)
var req1 = require('http').request({
  hostname: '127.0.0.1',
  port: 10000,
  path: '/',
  method: 'Post',
  headers: {
    "Transfer-Encoding": "chunked"
  },
  // agent: keepAliveAgent
}, (res) => {
  console.log('data1 response', res.statusCode, res.httpVersion, res.headers)
  res.setEncoding('utf8')
  res.on('error', (e) => {
    console.log("res1 error:", e)
  })
  res.on('data', (d) => {
    console.log('%j', d)
  })
  res.on('end', (d) => {
    console.log('data1:', 'end .')
  })
})
req1.on('error', (e) => {
  console.log("req1 error:", e)
})
var data = require('fs').readFileSync('./a.txt', 'utf-8')
console.log(Buffer.byteLength(data))
req1.write(data)

// console.log(keepAliveAgent.sockets)
// var req2 = require('http').request({
//   hostname: '127.0.0.1',
//   port: 10000,
//   path: '/',
//   method: 'Get',
//   headers: {
//     "Connection": "keep-alive"
//   },
//   agent: keepAliveAgent
// }, (res) => {
//   console.log('data2 response', res.httpVersion, res.headers)
//   res.setEncoding('utf8')
//   res.on('error', (e) => {
//     console.log("res2 error:", e)
//   })
//   res.on('data', (d) => {
//     console.log('data2:', d)
//   })
//   res.on('end', (d) => {
//     console.log('data2:', 'end .')
//   })
// })
// req2.on('error', (e) => {
//   console.log("req2 error:", e)
// })
// req2.end()
// console.log(keepAliveAgent.sockets)
// req.on('response', (res) => {
//   console.log('res response', res.statusCode, res.headers)
//   res.setEncoding('utf8')
//   res.on('data', (d) => {
//     console.log('res:%j', d)
//   })
//   res.on('end', () => {
//     console.log('res end')
//   })
//   res.on('error', (e) => {
//     console.log('res error:', e)
//   })
// })
// req.on('error', (e) => {
//   console.log('req error:', e)
// })
// // req.write('hello')
// // req.write('world')
// req.write("1")
// setTimeout(() => {
//   req.end()
//   req.end()
//   console.log(1)
//   req.write("1")
// }, 1000)


// var req2 = require('http').request({
//   hostname: '127.0.0.1',
//   port: 10000,
//   path: '/',
//   agent: keepAliveAgent,
//   headers: {
//     "Transfer-Encoding": "chunked"
//   }
// })
// // req2.on('response', (res) => {
// //   console.log('req2 response')
// // })
// req2.write('hello2')
// req2.write('world2')
// req2.end()


