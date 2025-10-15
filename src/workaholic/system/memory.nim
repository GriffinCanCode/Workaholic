## Memory optimization module
## Handles memory-related optimizations

import std/[strutils, osproc, asyncdispatch, re, streams]
import ../[types, config]

proc parseVMStat*(output: string): MemoryStats =
  ## Parse vm_stat output
  result = MemoryStats()
  
  let pageSize = 4096'i64  # macOS page size
  
  for line in output.splitLines():
    if "Pages free:" in line:
      let match = line.findAll(re"\d+")
      if match.len > 0:
        result.free = parseInt(match[0]) * pageSize
    elif "Pages active:" in line:
      let match = line.findAll(re"\d+")
      if match.len > 0:
        result.active = parseInt(match[0]) * pageSize
    elif "Pages inactive:" in line:
      let match = line.findAll(re"\d+")
      if match.len > 0:
        result.inactive = parseInt(match[0]) * pageSize
    elif "Pages wired down:" in line:
      let match = line.findAll(re"\d+")
      if match.len > 0:
        result.wired = parseInt(match[0]) * pageSize
    elif "Pages occupied by compressor:" in line:
      let match = line.findAll(re"\d+")
      if match.len > 0:
        result.compressed = parseInt(match[0]) * pageSize

proc getMemoryStats*(): Future[MemoryStats] {.async.} =
  ## Get current memory statistics
  try:
    let output = execProcess("vm_stat", options = {poUsePath})
    result = parseVMStat(output)
  except OSError:
    result = MemoryStats()

proc optimizeSystemMemory*(): Future[void] {.async.} =
  ## Optimize system memory
  try:
    # Purge inactive memory
    let cfg = loadConfig()
    let process = startProcess("sudo", args = ["-S", "purge"], 
                              options = {poUsePath, poStdErrToStdOut})
    process.inputStream.writeLine(cfg.sudoPassword)
    process.inputStream.close()
    discard process.waitForExit()
    process.close()
    
    # Sync filesystem buffers
    discard execProcess("sync", options = {poUsePath})
    
  except OSError:
    discard

