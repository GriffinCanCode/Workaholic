## Pipeline architecture for streaming cleanup operations
## Implements the actor model for concurrent processing

import std/[times, asyncdispatch, deques]
import ../types
import scanner, cleaner, scorer

type
  PipelineStage* = enum
    psScanning
    psScoring
    psCleaning
    psComplete
  
  ProgressCallback* = proc(progress: float, message: string) {.closure.}
  
  Pipeline* = ref object
    stage*: PipelineStage
    items*: Deque[CleanupItem]
    stats*: CleanupStats
    maxConcurrent*: int
    onProgress*: ProgressCallback
    ageFilterDays*: int

proc newPipeline*(maxConcurrent: int = 4, onProgress: ProgressCallback = nil, ageFilterDays: int = 7): Pipeline =
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
    maxConcurrent: maxConcurrent,
    onProgress: onProgress,
    ageFilterDays: ageFilterDays
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
  if not pipeline.onProgress.isNil:
    pipeline.onProgress(0.1, "Scanning cache directories...")
  
  var scanFutures: seq[Future[seq[CleanupItem]]]
  for i, cacheType in cacheTypes:
    scanFutures.add(pipeline.scan(cacheType))
  
  # Wait for all scans to complete
  var allItems: seq[CleanupItem]
  for i, future in scanFutures:
    let items = await future
    allItems.add(items)
    if not pipeline.onProgress.isNil:
      let progress = 0.1 + (0.2 * float(i + 1) / float(scanFutures.len))
      pipeline.onProgress(progress, "Scanned " & $allItems.len & " cache items...")
  
  # Score and prioritize
  if not pipeline.onProgress.isNil:
    pipeline.onProgress(0.35, "Analyzing and prioritizing cleanup items...")
  
  # Apply age filter if configured
  var filteredItems = allItems
  if pipeline.ageFilterDays > 0:
    filteredItems = filterByAge(allItems, pipeline.ageFilterDays)
    if not pipeline.onProgress.isNil:
      pipeline.onProgress(0.37, "Filtered to " & $filteredItems.len & " items older than " & $pipeline.ageFilterDays & " days")
  
  let scoredItems = pipeline.score(filteredItems)
  
  # Clean in parallel
  if not pipeline.onProgress.isNil:
    pipeline.onProgress(0.4, "Cleaning " & $scoredItems.len & " items...")
  
  discard await pipeline.clean(scoredItems)
  
  if not pipeline.onProgress.isNil:
    pipeline.onProgress(0.6, "Cleanup complete: " & $pipeline.stats.itemsDeleted & " items removed")
  
  # Update duration
  pipeline.stats.duration = getTime() - startTime
  pipeline.stage = psComplete
  
  result = pipeline.stats

