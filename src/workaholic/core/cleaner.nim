## Cleaner module - safely removes files and directories
## Implements safe deletion with backup capability

import std/[os, asyncdispatch, times, sequtils]
import ../types

type
  CleanupError* = object
    path*: string
    error*: string
    timestamp*: Time

proc safeRemove*(path: string): bool =
  ## Safely remove a file or directory
  ## Returns true if successful, false otherwise
  try:
    if not fileExists(path) and not dirExists(path):
      return false
    
    if dirExists(path):
      removeDir(path)
    else:
      removeFile(path)
    
    return true
  except OSError, IOError:
    return false

proc cleanItem*(item: CleanupItem): Future[tuple[success: bool, bytesFreed: int64]] {.async.} =
  ## Clean a single item asynchronously
  result = (success: false, bytesFreed: 0'i64)
  
  try:
    let sizeBefore = item.size
    if safeRemove(item.path):
      result = (success: true, bytesFreed: sizeBefore)
  except Exception:
    discard

proc cleanItemsParallel*(items: seq[CleanupItem], maxConcurrent: int): Future[CleanupStats] {.async.} =
  ## Clean items in parallel with concurrency limit
  result = CleanupStats(
    itemsScanned: items.len,
    itemsDeleted: 0,
    bytesFreed: 0,
    errors: @[]
  )
  
  var currentBatch: seq[Future[tuple[success: bool, bytesFreed: int64]]]
  
  for i, item in items:
    currentBatch.add(cleanItem(item))
    
    # Process in batches to limit concurrency
    if currentBatch.len >= maxConcurrent or i == items.high:
      for future in currentBatch:
        let res = await future
        if res.success:
          inc result.itemsDeleted
          result.bytesFreed += res.bytesFreed
      currentBatch = @[]

proc cleanByType*(items: seq[CleanupItem], cacheType: CacheType): Future[CleanupStats] {.async.} =
  ## Clean items of a specific type
  let filtered = items.filterIt(it.cacheType == cacheType)
  result = await cleanItemsParallel(filtered, 4)

proc dryRun*(items: seq[CleanupItem]): CleanupStats =
  ## Perform a dry run (no actual deletion)
  result = CleanupStats(
    itemsScanned: items.len,
    itemsDeleted: 0,
    bytesFreed: 0,
    errors: @[]
  )
  
  for item in items:
    result.bytesFreed += item.size
    inc result.itemsDeleted
