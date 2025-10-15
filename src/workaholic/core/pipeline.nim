## Pipeline architecture for streaming cleanup operations
## Implements the actor model for concurrent processing

import std/[os, tables, times, asyncdispatch, deques]
import ../types
import scanner, cleaner, scorer

type
  PipelineStage* = enum
    psScanning
    psScoring
    psCleaning
    psComplete
  
  Pipeline* = ref object
    stage*: PipelineStage
    items*: Deque[CleanupItem]
    stats*: CleanupStats
    maxConcurrent*: int

proc newPipeline*(maxConcurrent: int = 4): Pipeline =
  ## Create new cleanup pipeline
  result = Pipeline(
    stage: psScanning,
    items: initDeque[CleanupItem](),
    stats: CleanupStats(
      itemsScanned: 0,
      itemsDeleted: 0,
      bytesFreed: 0,
      duration: initDuration()
    ),
    maxConcurrent: maxConcurrent
  )

proc scan*(pipeline: Pipeline, cacheType: CacheType): Future[seq[CleanupItem]] {.async.} =
  ## Scan for cleanup items of specified type
  pipeline.stage = psScanning
  result = await scanCacheType(cacheType)
  pipeline.stats.itemsScanned += result.len

proc score*(pipeline: Pipeline, items: seq[CleanupItem]): seq[CleanupItem] =
  ## Score and prioritize cleanup items
  pipeline.stage = psScoring
  result = scoreAndPrioritize(items)

proc clean*(pipeline: Pipeline, items: seq[CleanupItem]): Future[CleanupStats] {.async.} =
  ## Clean items in parallel
  pipeline.stage = psCleaning
  result = await cleanItemsParallel(items, pipeline.maxConcurrent)
  pipeline.stats.itemsDeleted += result.itemsDeleted
  pipeline.stats.bytesFreed += result.bytesFreed

proc run*(pipeline: Pipeline, cacheTypes: seq[CacheType]): Future[CleanupStats] {.async.} =
  ## Run the complete pipeline
  let startTime = getTime()
  
  # Scan all cache types concurrently
  var scanFutures: seq[Future[seq[CleanupItem]]]
  for cacheType in cacheTypes:
    scanFutures.add(pipeline.scan(cacheType))
  
  # Wait for all scans to complete
  var allItems: seq[CleanupItem]
  for future in scanFutures:
    let items = await future
    allItems.add(items)
  
  # Score and prioritize
  let scoredItems = pipeline.score(allItems)
  
  # Clean in parallel
  let cleanStats = await pipeline.clean(scoredItems)
  
  # Update duration
  pipeline.stats.duration = getTime() - startTime
  pipeline.stage = psComplete
  
  result = pipeline.stats

