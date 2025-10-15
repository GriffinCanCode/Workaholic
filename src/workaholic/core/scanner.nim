## Scanner module - discovers cleanup candidates
## Uses parallel directory traversal for speed

import std/[os, times, asyncdispatch, tables, strutils]
import ../types

const CachePaths = {
  ctBrowser: @[
    "~/Library/Caches/com.apple.Safari",
    "~/Library/Application Support/Google/Chrome/Default/Cache",
    "~/Library/Application Support/Google/Chrome/Default/Code Cache",
    "~/Library/Application Support/Firefox/Profiles/*/cache2"
  ],
  ctDeveloper: @[
    "~/Library/Developer/Xcode/DerivedData",
    "~/Library/Developer/Xcode/Archives",
    "~/Library/Developer/CoreSimulator/Caches",
    "~/.cargo/registry/cache",
    "~/.npm/_cacache",
    "~/Library/Caches/Homebrew"
  ],
  ctApplication: @[
    "~/Library/Caches",
    "~/Library/Application Support/*/Cache",
    "~/Library/Containers/*/Data/Library/Caches"
  ],
  ctSystem: @[
    "~/Library/Logs"
  ],
  ctLogs: @[
    "~/Library/Logs",
    "~/Downloads/*.log",
    "~/Downloads/*.tmp"
  ]
}.toTable

proc expandPath(path: string): seq[string] =
  ## Expand path with wildcards
  result = @[]
  let expanded = expandTilde(path)
  
  if '*' in expanded:
    let parts = expanded.split('/')
    var currentPaths = @["/"]
    
    for part in parts:
      if part == "": continue
      var nextPaths: seq[string]
      
      for base in currentPaths:
        if '*' in part:
          try:
            for kind, path in walkDir(base):
              if kind == pcDir:
                let name = path.extractFilename
                if name.len > 0 and name[0] != '.':
                  nextPaths.add(path)
          except OSError:
            discard
        else:
          nextPaths.add(base / part)
      
      currentPaths = nextPaths
    
    result = currentPaths
  else:
    if dirExists(expanded) or fileExists(expanded):
      result.add(expanded)

proc getDirectorySize(path: string): int64 =
  ## Calculate directory size recursively
  result = 0
  try:
    for kind, file in walkDirRec(path):
      try:
        result += getFileSize(file)
      except OSError:
        discard
  except OSError:
    discard

proc scanPath(path: string, cacheType: CacheType): Future[seq[CleanupItem]] {.async.} =
  ## Scan a single path for cleanup items
  result = @[]
  
  let expandedPaths = expandPath(path)
  
  for expPath in expandedPaths:
    if not dirExists(expPath) and not fileExists(expPath):
      continue
    
    try:
      let info = getFileInfo(expPath)
      let size = if dirExists(expPath): getDirectorySize(expPath) else: getFileSize(expPath)
      
      if size > 0:
        var item = CleanupItem(
          path: expPath,
          cacheType: cacheType,
          size: size,
          lastAccessed: info.lastAccessTime,
          safe: true  # Will be validated by safety checker
        )
        item.score = calculateScore(item)
        result.add(item)
    except OSError:
      discard

proc scanCacheType*(cacheType: CacheType): Future[seq[CleanupItem]] {.async.} =
  ## Scan all paths for a specific cache type
  result = @[]
  
  if not CachePaths.hasKey(cacheType):
    return result
  
  var futures: seq[Future[seq[CleanupItem]]]
  for path in CachePaths[cacheType]:
    futures.add(scanPath(path, cacheType))
  
  for future in futures:
    let items = await future
    result.add(items)

