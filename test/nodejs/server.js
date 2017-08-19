require('net').createServer({
  allowHalfOpen: true
}, function (conn) {
  conn.on('data', (d) => {
    console.log('--> data ', d.toString())
  })
  conn.on('end', (d) => {
    console.log('end')
  })
  conn.on('finish', (d) => {
    console.log('finish')
  })
  conn.on('close', () => {
    console.log('close')
  })
  conn.on('error', (e) => {
    console.log('error', e)
  })
}).listen(10001)