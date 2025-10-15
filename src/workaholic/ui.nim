## TUI (Terminal User Interface) module
## Provides rich terminal interface with real-time updates

import std/[terminal, strformat, strutils, tables, times]
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
  let width = ui.width - 12
  let filled = int(progress * float(width))
  let empty = width - filled
  
  var bar = "│  "
  if label != "":
    bar &= label & " "
  
  # Color-code based on progress
  if progress < 0.33:
    bar &= $fgRed
  elif progress < 0.66:
    bar &= $fgYellow
  else:
    bar &= $fgGreen
  
  bar &= "■".repeat(filled)
  bar &= $resetStyle
  bar &= "□".repeat(empty)
  bar &= &" {int(progress * 100)}%"
  bar &= " ".repeat(ui.width - bar.len - 3)
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
    of opScan: $fgCyan
    of opAnalyze: $fgYellow
    of opClean: $fgMagenta
    of opOptimize: $fgBlue
    of opComplete: $fgGreen
  
  ui.drawLine(statusColor & $operation.kind & $resetStyle & ": " & operation.target, 2)
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
  ui.drawLine($fgCyan & "Memory:" & $resetStyle, 2)
  ui.displayMemoryStats(stats.memory)
  ui.drawLine("")
  
  # Disk section
  ui.drawLine($fgCyan & "Disk:" & $resetStyle, 2)
  ui.displayDiskStats(stats.disk)
  ui.drawLine("")
  
  ui.drawBottomBorder()
  
  flushFile(stdout)

proc showCompletion*(ui: UI) =
  ## Show completion screen
  eraseScreen()
  setCursorPos(0, 0)
  
  ui.drawBorder("Optimization Complete!")
  ui.drawLine("")
  
  # ASCII art celebration
  ui.drawLine("    ✨  🚀  ✨", 15)
  ui.drawLine("")
  ui.drawLine($fgGreen & "System optimization completed successfully!" & $resetStyle, 2)
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

