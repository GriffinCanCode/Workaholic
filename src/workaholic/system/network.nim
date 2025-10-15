## Network optimization module
## Handles network-related optimizations

import std/[osproc, asyncdispatch, streams]
import ../config

proc flushDNS*(): Future[void] {.async.} =
  ## Flush DNS cache
  try:
    let cfg = loadConfig()
    
    # Flush DNS cache
    var process = startProcess("sudo", args = ["-S", "dscacheutil", "-flushcache"],
                              options = {poUsePath, poStdErrToStdOut})
    process.inputStream.writeLine(cfg.sudoPassword)
    process.inputStream.close()
    discard process.waitForExit()
    process.close()
    
    # Restart mDNSResponder
    process = startProcess("sudo", args = ["-S", "killall", "-HUP", "mDNSResponder"],
                          options = {poUsePath, poStdErrToStdOut})
    process.inputStream.writeLine(cfg.sudoPassword)
    process.inputStream.close()
    discard process.waitForExit()
    process.close()
    
  except OSError:
    discard

proc optimizeTCP*(): Future[void] {.async.} =
  ## Optimize TCP settings
  try:
    let cfg = loadConfig()
    
    # Disable delayed ACK
    var process = startProcess("sudo", args = ["-S", "sysctl", "-w", "net.inet.tcp.delayed_ack=0"],
                              options = {poUsePath, poStdErrToStdOut})
    process.inputStream.writeLine(cfg.sudoPassword)
    process.inputStream.close()
    discard process.waitForExit()
    process.close()
    
  except OSError:
    discard

proc optimizeSystemNetwork*(): Future[void] {.async.} =
  ## Optimize network settings
  await flushDNS()
  await optimizeTCP()

