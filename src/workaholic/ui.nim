## TUI (Terminal User Interface) module
## Provides rich terminal interface with real-time updates

import std/[terminal, strformat, strutils, times]
import types, config

type
  UI* = ref object
    config*: Config
    currentOperation*: Operation
    systemStats*: SystemStats
    width*: int
    height*: int

proc initUI*(config: Config): UI =
  ## Initialize UI
  result = UI(
    config: config,
    currentOperation: Operation(kind: opScan, target: "", progress: 0.0, message: "Initializing..."),
    width: terminalWidth(),
    height: terminalHeight()
  )
  
  # Hide cursor for cleaner output
  hideCursor()

proc drawBorder*(ui: UI, title: string = "") =
  ## Draw a border box
  let width = ui.width - 4
  
  stdout.write("┌─")
  if title != "":
    stdout.write(" ", title, " ")
    stdout.write("─".repeat(width - title.len - 3))
  else:
    stdout.write("─".repeat(width))
  stdout.write("─┐\n")

proc drawBottomBorder*(ui: UI) =
  ## Draw bottom border
  let width = ui.width - 4
  stdout.write("└─")
  stdout.write("─".repeat(width))
  stdout.write("─┘\n")

proc drawLine*(ui: UI, text: string, padding: int = 2) =
  ## Draw a line with borders
  let width = ui.width - 4
  let paddedText = " ".repeat(padding) & text
  let remaining = width - paddedText.len
  stdout.write("│ ", paddedText, " ".repeat(max(0, remaining)), " │\n")

proc drawProgressBar*(ui: UI, progress: float, label: string = "") =
  ## Draw a progress bar
  let barWidth = ui.width - 12
  let filled = int(progress * float(barWidth))
  let empty = barWidth - filled
  
  # Calculate visual length (excluding ANSI codes)
  var visualLen = 2  # "│  "
  if label != "":
    visualLen += label.len + 1
  
  # Color-code based on progress
  var colorCode = ""
  if progress < 0.33:
    colorCode = ansiForegroundColorCode(fgRed)
  elif progress < 0.66:
    colorCode = ansiForegroundColorCode(fgYellow)
  else:
    colorCode = ansiForegroundColorCode(fgGreen)
  
  let percentStr = &" {int(progress * 100)}%"
  visualLen += filled + empty + percentStr.len
  
  let padding = max(0, ui.width - visualLen - 1)
  
  var bar = "│  "
  if label != "":
    bar &= label & " "
  bar &= colorCode
  bar &= "■".repeat(filled)
  bar &= ansiResetCode
  bar &= "□".repeat(empty)
  bar &= percentStr
  bar &= " ".repeat(padding)
  bar &= "│\n"
  
  stdout.write(bar)

proc displayMemoryStats*(ui: UI, stats: MemoryStats) =
  ## Display memory statistics
  ui.drawLine(&"Memory Free:     {formatBytes(stats.free)}", 4)
  ui.drawLine(&"Memory Active:   {formatBytes(stats.active)}", 4)
  ui.drawLine(&"Memory Inactive: {formatBytes(stats.inactive)}", 4)
  ui.drawLine(&"Memory Wired:    {formatBytes(stats.wired)}", 4)

proc displayDiskStats*(ui: UI, stats: DiskStats) =
  ## Display disk statistics
  let usedPercent = if stats.total > 0: (stats.used.float / stats.total.float) * 100 else: 0.0
  ui.drawLine(&"Disk Total:      {formatBytes(stats.total)}", 4)
  ui.drawLine(&"Disk Used:       {formatBytes(stats.used)} ({usedPercent:.1f}%)", 4)
  ui.drawLine(&"Disk Free:       {formatBytes(stats.free)}", 4)

proc updateOperation*(ui: UI, operation: Operation) =
  ## Update current operation and redraw
  ui.currentOperation = operation
  
  # Clear screen and redraw
  eraseScreen()
  setCursorPos(0, 0)
  
  # Title
  ui.drawBorder("Workaholic - System Optimizer")
  ui.drawLine("")
  
  # Status
  let statusColor = case operation.kind
    of opScan: ansiForegroundColorCode(fgCyan)
    of opAnalyze: ansiForegroundColorCode(fgYellow)
    of opClean: ansiForegroundColorCode(fgMagenta)
    of opOptimize: ansiForegroundColorCode(fgBlue)
    of opComplete: ansiForegroundColorCode(fgGreen)
  
  ui.drawLine(statusColor & $operation.kind & ansiResetCode & ": " & operation.target, 2)
  ui.drawLine(operation.message, 2)
  ui.drawLine("")
  
  # Progress bar
  ui.drawProgressBar(operation.progress)
  ui.drawLine("")
  
  ui.drawBottomBorder()
  
  flushFile(stdout)

proc updateSystemStats*(ui: UI, stats: SystemStats) =
  ## Update and display system stats
  ui.systemStats = stats
  
  eraseScreen()
  setCursorPos(0, 0)
  
  ui.drawBorder("System Statistics")
  ui.drawLine("")
  
  # Memory section
  ui.drawLine(ansiForegroundColorCode(fgCyan) & "Memory:" & ansiResetCode, 2)
  ui.displayMemoryStats(stats.memory)
  ui.drawLine("")
  
  # Disk section
  ui.drawLine(ansiForegroundColorCode(fgCyan) & "Disk:" & ansiResetCode, 2)
  ui.displayDiskStats(stats.disk)
  ui.drawLine("")
  
  ui.drawBottomBorder()
  
  flushFile(stdout)

proc showCompletion*(ui: UI, stats: CleanupStats, before: SystemStats, after: SystemStats) =
  ## Show completion screen with statistics
  eraseScreen()
  setCursorPos(0, 0)
  
  ui.drawBorder("Optimization Complete!")
  ui.drawLine("")
  
  # ASCII art celebration
  ui.drawLine("    ✨  🚀  ✨", 15)
  ui.drawLine("")
  ui.drawLine(ansiForegroundColorCode(fgGreen) & "System optimization completed successfully!" & ansiResetCode, 2)
  ui.drawLine("")
  
  # Cleanup Statistics
  if stats.itemsScanned > 0:
    ui.drawLine(ansiForegroundColorCode(fgCyan) & "Cleanup Results:" & ansiResetCode, 2)
    ui.drawLine(&"  Items Scanned:  {stats.itemsScanned}", 2)
    ui.drawLine(&"  Items Deleted:  {stats.itemsDeleted}", 2)
    ui.drawLine(&"  Space Freed:    {formatBytes(stats.bytesFreed)}", 2)
    let durationSecs = int(stats.duration.inMilliseconds / 1000)
    ui.drawLine(&"  Duration:       {durationSecs}s", 2)
    ui.drawLine("")
  
  # Before/After Comparison
  if before.memory.free > 0 and after.memory.free > 0:
    ui.drawLine(ansiForegroundColorCode(fgCyan) & "System Improvements:" & ansiResetCode, 2)
    
    # Memory comparison
    let memoryFreed = after.memory.free - before.memory.free
    if memoryFreed > 0:
      ui.drawLine(&"  Memory Freed:   {formatBytes(memoryFreed)}", 2)
    
    # Disk comparison
    let diskFreed = after.disk.free - before.disk.free
    if diskFreed > 0:
      ui.drawLine(&"  Disk Freed:     {formatBytes(diskFreed)}", 2)
    
    ui.drawLine("")
  
  ui.drawLine("Your system is now optimized for peak performance.", 2)
  ui.drawLine("")
  
  ui.drawBottomBorder()
  
  # Show cursor again
  showCursor()
  
  flushFile(stdout)

proc cleanup*(ui: UI) =
  ## Cleanup UI resources
  showCursor()
  eraseScreen()

