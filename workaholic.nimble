# Package information
version       = "2.0.0"
author        = "Workaholic Team"
description   = "High-performance system optimization tool for macOS"
license       = "MIT"
srcDir        = "src"
bin           = @["workaholic"]

# Dependencies
requires "nim >= 2.0.0"

# Tasks
task clean, "Clean build artifacts":
  exec "rm -rf src/nimcache"
  exec "rm -f workaholic"

task build, "Build the project":
  exec "nim c -d:release --opt:speed --mm:orc -o:workaholic src/workaholic.nim"

task dev, "Build for development":
  exec "nim c -d:debug --mm:orc -o:workaholic src/workaholic.nim"

task run, "Build and run":
  exec "nim c -r --mm:orc -o:workaholic src/workaholic.nim"

