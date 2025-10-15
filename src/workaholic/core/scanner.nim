## Scanner module - discovers cleanup candidates
## Uses parallel directory traversal for speed

import std/[os, asyncdispatch, tables, strutils]
import ../types

const CachePaths = {
  ctBrowser: @[
    # Safari
    "~/Library/Caches/com.apple.Safari",
    # Chrome
    "~/Library/Application Support/Google/Chrome/Default/Cache",
    "~/Library/Application Support/Google/Chrome/Default/Code Cache",
    "~/Library/Caches/Google/Chrome",
    # Firefox
    "~/Library/Application Support/Firefox/Profiles/*/cache2",
    "~/Library/Caches/Firefox",
    # Brave
    "~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cache",
    "~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Code Cache",
    # Edge
    "~/Library/Application Support/Microsoft Edge/Default/Cache",
    "~/Library/Application Support/Microsoft Edge/Default/Code Cache",
    # Arc
    "~/Library/Caches/company.thebrowser.Browser",
    # Opera
    "~/Library/Caches/com.operasoftware.Opera"
  ],
  ctDeveloper: @[
    # Xcode
    "~/Library/Developer/Xcode/DerivedData",
    "~/Library/Developer/Xcode/Archives",
    "~/Library/Developer/CoreSimulator/Caches",
    # Rust/Cargo
    "~/.cargo/registry/cache",
    # Node.js/npm
    "~/.npm/_cacache",
    # Yarn (centralized cache, safe to clear)
    "~/Library/Caches/Yarn",
    # Python package managers (centralized caches only)
    "~/Library/Caches/pip",
    "~/Library/Caches/pypoetry",
    # Go modules cache
    "~/Library/Caches/go-build",
    # Java/JVM build tools
    "~/.gradle/caches",
    "~/.m2/repository",
    # CocoaPods
    "~/Library/Caches/CocoaPods",
    # Homebrew
    "~/Library/Caches/Homebrew"
  ],
  ctApplication: @[
    # General app caches
    "~/Library/Caches",
    "~/Library/Application Support/*/Cache",
    "~/Library/Containers/*/Data/Library/Caches",
    # Specific high-usage apps (safe caches only)
    "~/Library/Application Support/Slack/Cache",
    "~/Library/Application Support/Slack/Code Cache",
    "~/Library/Application Support/Spotify/PersistentCache",
    "~/Library/Application Support/Code/Cache",
    "~/Library/Application Support/Code/CachedData",
    "~/Library/Application Support/Discord/Cache",
    "~/Library/Application Support/Discord/Code Cache"
  ],
  ctSystem: @[
    # System caches (safe to regenerate)
    "~/Library/Caches/com.apple.QuickLookThumbnails.thumbnailcache",
    "~/Library/Caches/com.apple.iconservices.store",
    # Font caches
    "~/Library/Caches/com.apple.FontRegistry"
  ],
  ctLogs: @[
    "~/Library/Logs",
    "~/Downloads/*.log",
    "~/Downloads/*.tmp",
    # Crash reports (old ones are safe to remove)
    "~/Library/Application Support/CrashReporter"
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
    for file in walkDirRec(path):
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

