## Intelligent scoring system for cleanup prioritization
## Uses heuristics to determine what should be cleaned first

import std/[algorithm, tables, times, sequtils]
import ../types

proc scoreAndPrioritize*(items: seq[CleanupItem]): seq[CleanupItem] =
  ## Score items and sort by priority (highest score first)
  result = items
  
  # Calculate scores for all items
  for i in 0..<result.len:
    result[i].score = calculateScore(result[i])
  
  # Sort by score descending (highest priority first)
  result.sort do (a, b: CleanupItem) -> int:
    cmp(b.score, a.score)

proc filterBySafety*(items: seq[CleanupItem], safeOnly: bool): seq[CleanupItem] =
  ## Filter items by safety level
  if safeOnly:
    result = items.filterIt(it.safe)
  else:
    result = items

proc filterByAge*(items: seq[CleanupItem], minAgeDays: int): seq[CleanupItem] =
  ## Filter items by minimum age
  let cutoffTime = getTime() - initDuration(days = minAgeDays)
  result = items.filterIt(it.lastAccessed < cutoffTime)

proc filterBySize*(items: seq[CleanupItem], minSizeMB: int64): seq[CleanupItem] =
  ## Filter items by minimum size
  let minSizeBytes = minSizeMB * 1024 * 1024
  result = items.filterIt(it.size >= minSizeBytes)

proc getTopItems*(items: seq[CleanupItem], count: int): seq[CleanupItem] =
  ## Get top N items by score
  result = items[0 ..< min(count, items.len)]

proc groupByType*(items: seq[CleanupItem]): Table[CacheType, seq[CleanupItem]] =
  ## Group items by cache type
  result = initTable[CacheType, seq[CleanupItem]]()
  
  for item in items:
    if not result.hasKey(item.cacheType):
      result[item.cacheType] = @[]
    result[item.cacheType].add(item)

proc calculateTotalSize*(items: seq[CleanupItem]): int64 =
  ## Calculate total size of all items
  result = 0
  for item in items:
    result += item.size

