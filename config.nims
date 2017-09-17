import ospaths, strutils

proc reGenDoc(filename: string) =
  writeFile(filename,
            replace(
              replace(readFile(filename), 
                      """href="/tree/master/node""", 
                      """href="https://github.com/tulayang/nimnode/tree/master/node""" ),
              """href="/edit/devel/node""",
              """href="https://github.com/tulayang/nimnode/edit/master/node""" ))

template runTest(name: string) =
  # TODO: windows tests
  withDir thisDir():
    mkDir "bin"
    --r
    --o:"""bin/""" name
    --verbosity:0
    --path:"""."""
    --passC:"""-I/opt/libuv/include"""
    --putenv:"""LD_LIBRARY_PATH=/opt/libuv/lib"""
    when defined(macosx):
      --passL:"""/opt/libuv/lib/libuv.dylib"""
    else:
      --passL:"""/opt/libuv/lib/libuv.so"""
    setCommand "c", "test/" & name & ".nim"

template runBenchmark(name: string) =
  # TODO: windows tests
  withDir thisDir():
    mkDir "bin"
    --r
    --o:"""bin/""" name
    --verbosity:0
    --path:"""."""
    --passC:"""-I/opt/libuv/include"""
    --putenv:"""LD_LIBRARY_PATH=/opt/libuv/lib"""
    when defined(macosx):
      --passL:"""/opt/libuv/lib/libuv.dylib"""
    else:
      --passL:"""/opt/libuv/lib/libuv.so"""
    setCommand "c", "benchmark/" & name & ".nim"

task build, "Compile node into a library":
  --app:lib
  --d:release
  setCommand "c", "node"

task doc, "Generate documentation":
  exec "mkdir -p " & thisDir() / "doc/uv"
  for name in [
    "uv_async",  "uv_check", "uv_dns",   "uv_error", "uv_fs_event", "uv_fs_poll", "uv_handle",  "uv_idle",
    "uv_loop",   "uv_misc",  "uv_pipe",  "uv_poll",  "uv_prepare",  "uv_process", "uv_request", "uv_signal",
    "uv_stream", "uv_tcp",   "uv_timer", "uv_tty",   "uv_udp",      "uv_version"
  ]:
    exec "nim doc2 -o:$outfile --docSeeSrcUrl:$url $file" % [
      "outfile", thisDir() / "doc/uv" / name & ".html",
      "url",     "https://github.com/tulayang/nimnode/blob/master",
      "file",    thisDir() / "node/uv" / name & ".nim"
    ]
    reGenDoc thisDir() / "doc/uv" / name & ".html"
  for name in [
    "error",  "loop", "timers", "streams", "nettype", "net"
  ]:
    exec "nim doc2 -o:$outfile --docSeeSrcUrl:$url $file" % [
      "outfile", thisDir() / "doc" / name & ".html",
      "url",     "https://github.com/tulayang/nimnode/blob/master",
      "file",    thisDir() / "node" / name & ".nim"
    ]
    reGenDoc thisDir() / "doc" / name & ".html"
  exec "nim rst2html -o:$outfile $file" % [
    "outfile", thisDir() / "doc" / "index.html",
    "file",    thisDir() / "doc" / "index.rst"
  ]

task test, "Run test tests":
  runTest "test"

task test_error, "Run error tests":
  runTest "test_error"

task test_timers, "Run timers tests":
  runTest "test_timers"

task test_net, "Run net tests":
  runTest "test_net"

task bench_stdlib_asynchttpserver, "Run stdlib_asynchttpserver benchmark":
  runBenchmark "bench_stdlib_asynchttpserver"

task bench_http_server, "Run httpserver benchmark":
  runBenchmark "bench_httpserver"
