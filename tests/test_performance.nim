## Performance Tests
## Benchmarks Nim version vs Python version

import std/[os, osproc, times, strutils]

proc formatBytes(bytes: int64): string =
  const units = ["B", "KB", "MB", "GB", "TB"]
  var size = float(bytes)
  var unitIdx = 0
  
  while size >= 1024.0 and unitIdx < units.high:
    size = size / 1024.0
    inc unitIdx
  
  result = size.formatFloat(ffDecimal, 2) & " " & units[unitIdx]

proc timeCommand(cmd: string, args: seq[string] = @[]): Duration =
  ## Time how long a command takes to execute
  let startTime = cpuTime()
  discard execProcess(cmd, args = args, options = {poUsePath})
  let endTime = cpuTime()
  result = initDuration(milliseconds = int((endTime - startTime) * 1000))

proc testScanSpeed() =
  ## Test how fast we can scan directories
  echo "🏃 Testing directory scan speed..."
  
  let homeDir = getHomeDir()
  let testDir = homeDir / "Library/Caches"
  
  if not dirExists(testDir):
    echo "  ⚠️  Test directory doesn't exist, skipping"
    return
  
  let startTime = cpuTime()
  var fileCount = 0
  var totalSize: int64 = 0
  
  for path in walkDirRec(testDir):
    inc fileCount
    try:
      totalSize += getFileSize(path)
    except:
      discard
    
    if fileCount >= 1000:  # Limit for speed
      break
  
  let duration = cpuTime() - startTime
  
  echo "  Scanned ", fileCount, " files in ", duration.formatFloat(ffDecimal, 3), "s"
  echo "  Speed: ", int(float(fileCount) / duration), " files/second"
  echo "  Total size scanned: ", formatBytes(totalSize)
  echo ""

proc testMemoryUsage() =
  ## Test memory usage of the binary
  echo "🧠 Testing memory usage..."
  
  let output = execProcess("ps", args = ["aux"], options = {poUsePath})
  
  for line in output.splitLines():
    if "workaholic" in line:
      let parts = line.splitWhitespace()
      if parts.len > 5:
        echo "  Memory (RSS): ", parts[5], " KB"
        let memMB = parseInt(parts[5]) div 1024
        if memMB < 50:
          echo "    ✅ Excellent: Under 50MB"
        elif memMB < 100:
          echo "    ✅ Good: Under 100MB"
        else:
          echo "    ⚠️  High memory usage"
      break
  
  echo ""

proc testBinarySize() =
  ## Check compiled binary size
  echo "📦 Testing binary size..."
  
  let binaryPath = getCurrentDir() / "workaholic"
  
  if fileExists(binaryPath):
    let size = getFileSize(binaryPath)
    echo "  Binary size: ", formatBytes(size)
    
    if size < 1_000_000:  # < 1MB
      echo "    ✅ Excellent: Under 1MB"
    elif size < 5_000_000:  # < 5MB
      echo "    ✅ Good: Under 5MB"
    else:
      echo "    ⚠️  Large binary"
  else:
    echo "  ❌ Binary not found"
  
  echo ""

proc testStartupTime() =
  ## Test how fast the binary starts
  echo "⚡ Testing startup time..."
  
  let times: seq[Duration] = @[]
  
  for i in 1..5:
    let start = cpuTime()
    # Try to run help quickly
    discard execProcess("./workaholic", args = ["--version"], options = {poUsePath, poStdErrToStdOut})
    let duration = cpuTime() - start
    echo "  Run ", i, ": ", (duration * 1000).formatFloat(ffDecimal, 2), "ms"
  
  echo ""

when isMainModule:
  echo """
╔══════════════════════════════════════════════════╗
║   WORKAHOLIC PERFORMANCE BENCHMARK SUITE         ║
║   Measuring speed and efficiency                 ║
╚══════════════════════════════════════════════════╝
"""
  echo ""
  
  testBinarySize()
  testScanSpeed()
  testStartupTime()
  testMemoryUsage()
  
  echo "✅ Performance tests complete!"

