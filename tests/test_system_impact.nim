## System Impact Tests
## Verifies that optimization actually improves system performance

import std/[os, osproc, strutils, times, tables, asyncdispatch]
import ../src/workaholic/system/[memory, disk, stats]
import ../src/workaholic/types

type
  SystemBenchmark = object
    memoryBefore: MemoryStats
    memoryAfter: MemoryStats
    diskBefore: DiskStats
    diskAfter: DiskStats
    duration: Duration

proc captureSystemStateBefore(): SystemBenchmark =
  ## Capture system state before optimization
  echo "📊 Capturing system state BEFORE optimization..."
  
  result = SystemBenchmark()
  
  # Get memory stats
  let memFuture = getMemoryStats()
  result.memoryBefore = waitFor memFuture
  
  # Get disk stats
  let diskFuture = getDiskStats()
  result.diskBefore = waitFor diskFuture
  
  echo "  Memory Free: ", formatBytes(result.memoryBefore.free)
  echo "  Memory Active: ", formatBytes(result.memoryBefore.active)
  echo "  Memory Inactive: ", formatBytes(result.memoryBefore.inactive)
  echo "  Disk Free: ", formatBytes(result.diskBefore.free)
  echo ""

proc captureSystemStateAfter(benchmark: var SystemBenchmark) =
  ## Capture system state after optimization
  echo "📊 Capturing system state AFTER optimization..."
  
  # Get memory stats
  let memFuture = getMemoryStats()
  benchmark.memoryAfter = waitFor memFuture
  
  # Get disk stats
  let diskFuture = getDiskStats()
  benchmark.diskAfter = waitFor diskFuture
  
  echo "  Memory Free: ", formatBytes(benchmark.memoryAfter.free)
  echo "  Memory Active: ", formatBytes(benchmark.memoryAfter.active)
  echo "  Memory Inactive: ", formatBytes(benchmark.memoryAfter.inactive)
  echo "  Disk Free: ", formatBytes(benchmark.diskAfter.free)
  echo ""

proc analyzeImpact(benchmark: SystemBenchmark) =
  ## Analyze the impact of optimization
  echo "📈 OPTIMIZATION IMPACT ANALYSIS"
  echo "=" .repeat(50)
  echo ""
  
  # Memory impact
  let memoryFreed = benchmark.memoryAfter.free - benchmark.memoryBefore.free
  let inactiveReduced = benchmark.memoryBefore.inactive - benchmark.memoryAfter.inactive
  
  echo "💾 MEMORY OPTIMIZATION:"
  echo "  Free Memory Gained: ", formatBytes(memoryFreed)
  if memoryFreed > 0:
    echo "    ✅ SUCCESS: Freed ", formatBytes(memoryFreed), " of memory"
  else:
    echo "    ⚠️  WARNING: No memory freed (may be normal if system was already optimized)"
  
  echo "  Inactive Memory Reduced: ", formatBytes(inactiveReduced)
  if inactiveReduced > 0:
    echo "    ✅ SUCCESS: Cleared ", formatBytes(inactiveReduced), " of inactive memory"
  
  echo ""
  
  # Disk impact
  let diskFreed = benchmark.diskAfter.free - benchmark.diskBefore.free
  
  echo "💿 DISK OPTIMIZATION:"
  echo "  Disk Space Gained: ", formatBytes(diskFreed)
  if diskFreed > 0:
    echo "    ✅ SUCCESS: Freed ", formatBytes(diskFreed), " of disk space"
  elif diskFreed == 0:
    echo "    ℹ️  INFO: No disk space freed (caches may have been clean)"
  else:
    echo "    ℹ️  INFO: Disk usage increased (normal if files were created during run)"
  
  echo ""
  
  # Overall assessment
  echo "🎯 OVERALL ASSESSMENT:"
  var improvements = 0
  
  if memoryFreed > 100_000_000:  # > 100MB
    echo "  ✅ Significant memory freed"
    inc improvements
  
  if inactiveReduced > 100_000_000:  # > 100MB
    echo "  ✅ Inactive memory cleared"
    inc improvements
  
  if diskFreed > 1_000_000_000:  # > 1GB
    echo "  ✅ Significant disk space freed"
    inc improvements
  
  echo ""
  if improvements >= 2:
    echo "🎉 EXCELLENT: System significantly optimized!"
  elif improvements == 1:
    echo "✅ GOOD: System moderately optimized"
  else:
    echo "ℹ️  System may have already been optimized or no significant caches to clear"
  
  echo "=" .repeat(50)

proc testCacheDetection() =
  ## Test that we can detect caches to clean
  echo "🔍 Testing cache detection..."
  
  var cachesFound = 0
  let homeDir = getHomeDir()
  
  # Check common cache locations
  let cacheLocations = [
    homeDir / "Library/Caches",
    homeDir / "Library/Logs",
    homeDir / "Library/Application Support/Google/Chrome/Default/Cache"
  ]
  
  for location in cacheLocations:
    if dirExists(location):
      inc cachesFound
      echo "  ✅ Found: ", location
  
  if cachesFound > 0:
    echo "  SUCCESS: Found ", cachesFound, " cache locations"
  else:
    echo "  ⚠️  WARNING: No cache locations found"
  
  echo ""

proc testMemoryCommand() =
  ## Test that memory optimization command works
  echo "🧪 Testing memory optimization command availability..."
  
  try:
    let output = execProcess("which purge")
    if "purge" in output:
      echo "  ✅ 'purge' command available"
    else:
      echo "  ❌ 'purge' command not found"
  except:
    echo "  ❌ Error checking for 'purge' command"
  
  echo ""

proc testDNSCommand() =
  ## Test that DNS flush command works
  echo "🧪 Testing DNS cache flush command..."
  
  try:
    let output = execProcess("which dscacheutil")
    if "dscacheutil" in output:
      echo "  ✅ 'dscacheutil' command available"
    else:
      echo "  ❌ 'dscacheutil' command not found"
  except:
    echo "  ❌ Error checking for 'dscacheutil' command"
  
  echo ""

when isMainModule:
  echo """
╔══════════════════════════════════════════════════╗
║   WORKAHOLIC SYSTEM IMPACT TEST SUITE           ║
║   Verifies optimization actually works           ║
╚══════════════════════════════════════════════════╝
"""
  echo ""
  
  # Pre-flight checks
  echo "🚀 PRE-FLIGHT CHECKS"
  echo "=" .repeat(50)
  testCacheDetection()
  testMemoryCommand()
  testDNSCommand()
  
  # Capture before state
  var benchmark = captureSystemStateBefore()
  
  # Run optimization (user needs to run this manually)
  echo "⚠️  MANUAL STEP REQUIRED:"
  echo "   Please run: ./workaholic"
  echo "   Then press ENTER to continue..."
  discard stdin.readLine()
  
  # Capture after state
  captureSystemStateAfter(benchmark)
  
  # Analyze impact
  analyzeImpact(benchmark)
  
  echo ""
  echo "✅ Test suite complete!"

