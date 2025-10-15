## macOS Keychain integration for secure password storage
## Uses the `security` command-line tool to access Keychain

import std/[osproc, strutils]

const
  KeychainService = "workaholic"
  KeychainAccount = "sudo"

proc keychainGet*(service: string = KeychainService, account: string = KeychainAccount): string =
  ## Retrieve password from macOS Keychain
  ## Returns empty string if not found
  result = ""
  
  try:
    let cmd = "security find-generic-password -s \"" & service & 
              "\" -a \"" & account & "\" -w"
    let output = execProcess(cmd, options = {poUsePath, poStdErrToStdOut})
    
    # Remove trailing newline
    result = output.strip()
    
    # If output contains "password could not be found", return empty
    if "could not be found" in result.toLower():
      result = ""
      
  except OSError:
    result = ""

proc keychainSet*(password: string, service: string = KeychainService, account: string = KeychainAccount): bool =
  ## Store password in macOS Keychain
  ## Returns true if successful
  result = false
  
  try:
    # First, try to delete existing entry
    discard execProcess("security delete-generic-password -s \"" & service & 
                       "\" -a \"" & account & "\"", 
                       options = {poUsePath, poStdErrToStdOut})
    
    # Add new entry
    let cmd = "security add-generic-password -s \"" & service & 
              "\" -a \"" & account & "\" -w \"" & password & "\""
    let exitCode = execCmd(cmd)
    result = (exitCode == 0)
    
  except OSError:
    result = false

proc keychainDelete*(service: string = KeychainService, account: string = KeychainAccount): bool =
  ## Delete password from macOS Keychain
  ## Returns true if successful
  result = false
  
  try:
    let cmd = "security delete-generic-password -s \"" & service & 
              "\" -a \"" & account & "\""
    let exitCode = execCmd(cmd)
    result = (exitCode == 0)
    
  except OSError:
    result = false

proc keychainExists*(service: string = KeychainService, account: string = KeychainAccount): bool =
  ## Check if a password exists in Keychain
  result = false
  
  try:
    let cmd = "security find-generic-password -s \"" & service & 
              "\" -a \"" & account & "\""
    let output = execProcess(cmd, options = {poUsePath, poStdErrToStdOut})
    result = "could not be found" notin output.toLower()
    
  except OSError:
    result = false

