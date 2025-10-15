## Main entry point for Workaholic system optimizer
## Orchestrates the entire cleanup and optimization pipeline

import std/[terminal, asyncdispatch, tables]
import workaholic/[types, config, ui, core/pipeline, core/orchestrator]

proc displayBanner() =
  styledEcho(fgCyan, styleBright, """
╦ ╦╔═╗╦═╗╦╔═╔═╗╦ ╦╔═╗╦  ╦╔═╗
║║║║ ║╠╦╝╠╩╗╠═╣╠═╣║ ║║  ║║  
╚╩╝╚═╝╩╚═╩ ╩╩ ╩╩ ╩╚═╝╩═╝╩╚═╝
""")
  styledEcho(fgWhite, "System Optimization Tool v2.0")
  echo ""

proc main() {.async.} =
  try:
    # Display banner
    displayBanner()
    
    # Load configuration
    let cfg = loadConfig()
    
    # Initialize UI
    let ui = initUI(cfg)
    
    # Create orchestrator
    let orchestrator = newOrchestrator(cfg, ui)
    
    # Run the optimization pipeline
    await orchestrator.run()
    
    # Display completion with stats
    ui.showCompletion(
      orchestrator.stats.getOrDefault("cleanup"),
      orchestrator.systemStatsBefore,
      orchestrator.systemStatsAfter
    )
    
  except ConfigError as e:
    styledEcho(fgRed, styleBright, "Configuration Error: ", resetStyle, e.msg)
    quit(1)
  except SystemError as e:
    styledEcho(fgRed, styleBright, "System Error: ", resetStyle, e.msg)
    quit(1)
  except Exception as e:
    styledEcho(fgRed, styleBright, "Unexpected Error: ", resetStyle, e.msg)
    quit(1)

when isMainModule:
  waitFor main()

