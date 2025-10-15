## Core type definitions used throughout the application

import std/[times, strutils]

type
  SystemError* = object of CatchableError
  
  CacheType* = enum
    ctBrowser = "Browser"
    ctDeveloper = "Developer"
    ctApplication = "Application"
    ctSystem = "System"
    ctLogs = "Logs"
  
  CleanupItem* = object
    path*: string
    cacheType*: CacheType
    size*: int64           # in bytes
    lastAccessed*: Time
    score*: float          # priority score
    safe*: bool            # is it safe to delete?
  
  CleanupStats* = object
    itemsScanned*: int
    itemsDeleted*: int
    bytesFreed*: int64
    duration*: Duration
    errors*: seq[string]
  
  MemoryStats* = object
    free*: int64
    active*: int64
    inactive*: int64
    wired*: int64
    compressed*: int64
  
  DiskStats* = object
    total*: int64
    free*: int64
    used*: int64
  
  SystemStats* = object
    memory*: MemoryStats
    disk*: DiskStats
    timestamp*: Time
  
  OperationKind* = enum
    opScan = "Scanning"
    opAnalyze = "Analyzing"
    opClean = "Cleaning"
    opOptimize = "Optimizing"
    opComplete = "Complete"
  
  Operation* = object
    kind*: OperationKind
    target*: string
    progress*: float       # 0.0 to 1.0
    message*: string

proc formatBytes*(bytes: int64): string =
  ## Format bytes in human-readable format
  const units = ["B", "KB", "MB", "GB", "TB"]
  var size = float(bytes)
  var unitIdx = 0
  
  while size >= 1024.0 and unitIdx < units.high:
    size = size / 1024.0
    inc unitIdx
  
  result = size.formatFloat(ffDecimal, 2) & " " & units[unitIdx]

proc calculateScore*(item: CleanupItem): float =
  ## Calculate priority score for cleanup item
  ## Higher score = higher priority to delete
  ## Formula: (size × age_days × safety_factor) / (access_frequency + 1)
  
  let ageInDays = (getTime() - item.lastAccessed).inDays.float
  let sizeMB = item.size.float / (1024.0 * 1024.0)
  let safetyFactor = if item.safe: 1.0 else: 0.3
  
  result = (sizeMB * ageInDays * safetyFactor) / (1.0 + (1.0 / max(ageInDays, 1.0)))

