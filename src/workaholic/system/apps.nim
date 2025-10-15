## Application management module
## Handles closing and managing running applications

import std/[strutils, asyncdispatch, osproc, sequtils]

proc getRunningApps*(): seq[string] =
  ## Get list of running applications
  result = @[]
  
  let script = """
    tell application "System Events"
      set running_apps to name of every application process where background only is false
    end tell
  """
  
  try:
    let output = execProcess("osascript", args = ["-e", script], options = {poUsePath})
    if output != "":
      for app in output.split(", "):
        let cleanApp = app.strip()
        if cleanApp != "":
          result.add(cleanApp)
  except OSError:
    discard

proc quitApp*(appName: string): Future[bool] {.async.} =
  ## Quit a single application gracefully
  result = false
  
  let script = "tell application \"" & appName & "\" to quit"
  
  try:
    discard execProcess("osascript", args = ["-e", script], options = {poUsePath})
    result = true
  except OSError:
    discard

proc closeUnnecessaryApps*(protectedApps: seq[string]): Future[void] {.async.} =
  ## Close all apps except protected ones
  let running = getRunningApps()
  let protectedLower = protectedApps.mapIt(it.toLower())
  
  for app in running:
    if app.toLower() notin protectedLower:
      discard await quitApp(app)
      # Small delay between quits
      await sleepAsync(500)

