## Orchestrator - coordinates the entire optimization workflow
## Manages pipeline execution and system optimization

import std/[asyncdispatch, times, tables]
import ../[config, types]
import ../system/[apps, memory, disk, network, stats]
import pipeline, scanner, scorer, cleaner

type
  Orchestrator* = ref object
    config*: Config
    pipeline*: Pipeline
    stats*: Table[string, CleanupStats]
    systemStatsBefore*: SystemStats
    systemStatsAfter*: SystemStats

proc newOrchestrator*(config: Config): Orchestrator =
  ## Create new orchestrator
  result = Orchestrator(
    config: config,
    pipeline: newPipeline(config.parallelJobs),
    stats: initTable[string, CleanupStats]()
  )

proc closeApps*(orchestrator: Orchestrator) {.async.} =
  ## Close unnecessary applications
  await closeUnnecessaryApps(orchestrator.config.protectedApps)

proc optimizeMemory*(orchestrator: Orchestrator) {.async.} =
  ## Optimize system memory
  if orchestrator.config.optimization.memory:
    await optimizeSystemMemory()

proc optimizeDisk*(orchestrator: Orchestrator) {.async.} =
  ## Optimize disk usage
  if orchestrator.config.optimization.disk:
    await optimizeSystemDisk()

proc optimizeNetwork*(orchestrator: Orchestrator) {.async.} =
  ## Optimize network settings
  if orchestrator.config.optimization.network:
    await optimizeSystemNetwork()

proc run*(orchestrator: Orchestrator, ui: auto) {.async.} =
  ## Run the complete optimization workflow
  
  # Capture initial system stats
  orchestrator.systemStatsBefore = await getSystemStats()
  ui.updateSystemStats(orchestrator.systemStatsBefore)
  
  # Phase 1: Close applications
  ui.updateOperation(Operation(
    kind: opScan,
    target: "Applications",
    progress: 0.0,
    message: "Closing unnecessary applications..."
  ))
  await orchestrator.closeApps()
  
  # Phase 2: Scan and clean caches
  var cacheTypes: seq[CacheType] = @[]
  if orchestrator.config.cleaning.browserCaches:
    cacheTypes.add(ctBrowser)
  if orchestrator.config.cleaning.developerCaches:
    cacheTypes.add(ctDeveloper)
  if orchestrator.config.cleaning.applicationCaches:
    cacheTypes.add(ctApplication)
  if orchestrator.config.cleaning.systemLogs:
    cacheTypes.add(ctLogs)
  
  ui.updateOperation(Operation(
    kind: opScan,
    target: "Caches",
    progress: 0.0,
    message: "Scanning for cleanup candidates..."
  ))
  
  let cleanStats = await orchestrator.pipeline.run(cacheTypes)
  orchestrator.stats["cleanup"] = cleanStats
  
  # Phase 3: Optimize system
  if orchestrator.config.optimization.memory:
    ui.updateOperation(Operation(
      kind: opOptimize,
      target: "Memory",
      progress: 0.66,
      message: "Optimizing memory..."
    ))
    await orchestrator.optimizeMemory()
  
  if orchestrator.config.optimization.disk:
    ui.updateOperation(Operation(
      kind: opOptimize,
      target: "Disk",
      progress: 0.77,
      message: "Optimizing disk..."
    ))
    await orchestrator.optimizeDisk()
  
  if orchestrator.config.optimization.network:
    ui.updateOperation(Operation(
      kind: opOptimize,
      target: "Network",
      progress: 0.88,
      message: "Optimizing network..."
    ))
    await orchestrator.optimizeNetwork()
  
  # Capture final system stats
  orchestrator.systemStatsAfter = await getSystemStats()
  ui.updateSystemStats(orchestrator.systemStatsAfter)
  
  ui.updateOperation(Operation(
    kind: opComplete,
    target: "All",
    progress: 1.0,
    message: "Optimization complete!"
  ))

