## Configuration management
## Handles loading, validating, and providing access to configuration

import std/[os, strutils, parsecfg]
import system/keychain

type
  ConfigError* = object of CatchableError
  
  SafetyLevel* = enum
    slConservative = "conservative"
    slBalanced = "balanced"
    slAggressive = "aggressive"
  
  CleaningConfig* = object
    browserCaches*: bool
    developerCaches*: bool
    applicationCaches*: bool
    systemLogs*: bool
    ageFilterDays*: int
  
  OptimizationConfig* = object
    memory*: bool
    disk*: bool
    network*: bool
  
  Config* = object
    safetyLevel*: SafetyLevel
    showDryRun*: bool
    parallelJobs*: int
    protectedApps*: seq[string]
    cleaning*: CleaningConfig
    optimization*: OptimizationConfig
    sudoPassword*: string

proc getConfigPath(): string =
  ## Get configuration file path
  result = getHomeDir() / ".config" / "workaholic" / "config.toml"
  if not fileExists(result):
    result = getCurrentDir() / "config.toml"

proc getDefaultConfig(): Config =
  ## Return default configuration
  result = Config(
    safetyLevel: slBalanced,
    showDryRun: true,
    parallelJobs: 4,
    protectedApps: @["Terminal", "Cursor", "Google Chrome", "FaceTime", "zoom.us", "Zoom", "Safari", "Brave Browser", "Microsoft Edge"],
    cleaning: CleaningConfig(
      browserCaches: true,
      developerCaches: true,
      applicationCaches: true,
      systemLogs: true,
      ageFilterDays: 7
    ),
    optimization: OptimizationConfig(
      memory: true,
      disk: true,
      network: true
    )
  )

proc loadSudoPassword(): string =
  ## Load sudo password with security priority:
  ## 1. macOS Keychain (most secure)
  ## 2. Environment variable
  ## 3. .env file (least secure)
  
  # Try macOS Keychain first (most secure)
  result = keychainGet()
  if result != "":
    return result
  
  # Try environment variable
  result = getEnv("SUDO_PASSWORD")
  if result != "":
    return result
  
  # Fall back to .env file
  let envPath = getHomeDir() / ".workaholic" / ".env"
  if fileExists(envPath):
    for line in lines(envPath):
      if line.startsWith("SUDO_PASSWORD="):
        result = line[14..^1].strip()
        return result

proc loadConfig*(): Config =
  ## Load configuration from file or use defaults
  result = getDefaultConfig()
  
  let configPath = getConfigPath()
  if not fileExists(configPath):
    return result
  
  try:
    var dict = loadConfig(configPath)
    
    # Parse general settings
    if dict.getSectionValue("general", "safety_level") != "":
      let level = dict.getSectionValue("general", "safety_level")
      case level
      of "conservative": result.safetyLevel = slConservative
      of "balanced": result.safetyLevel = slBalanced
      of "aggressive": result.safetyLevel = slAggressive
      else: discard
    
    # Parse protected apps
    let apps = dict.getSectionValue("protected_apps", "always_keep")
    if apps != "":
      result.protectedApps = @[]
      for app in apps.split(','):
        result.protectedApps.add(app.strip(chars = {' ', '"', '[', ']'}))
    
    # Load sudo password
    result.sudoPassword = loadSudoPassword()
    
  except Exception as e:
    raise newException(ConfigError, "Failed to load config: " & e.msg)

proc validate*(cfg: Config) =
  ## Validate configuration
  if cfg.sudoPassword == "":
    raise newException(ConfigError, 
      "SUDO_PASSWORD not found.\n" &
      "To set it securely, run: security add-generic-password -s workaholic -a sudo -w\n" &
      "Or set SUDO_PASSWORD environment variable or create ~/.workaholic/.env")
  
  if cfg.parallelJobs < 1 or cfg.parallelJobs > 16:
    raise newException(ConfigError, 
      "parallel_jobs must be between 1 and 16")

proc setSudoPassword*(password: string): bool =
  ## Store sudo password in macOS Keychain securely
  ## Returns true if successful
  result = keychainSet(password)

