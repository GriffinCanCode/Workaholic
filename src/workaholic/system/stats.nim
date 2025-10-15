## System statistics aggregation
## Combines memory, disk, and other stats

import std/[asyncdispatch, times]
import ../types
import memory, disk

proc getSystemStats*(): Future[SystemStats] {.async.} =
  ## Get all system statistics
  result = SystemStats(
    timestamp: getTime()
  )
  
  result.memory = await getMemoryStats()
  result.disk = await getDiskStats()

proc compareStats*(before, after: SystemStats): tuple[memoryFreed: int64, diskFreed: int64] =
  ## Compare two system stats snapshots
  result.memoryFreed = after.memory.free - before.memory.free
  result.diskFreed = after.disk.free - before.disk.free

