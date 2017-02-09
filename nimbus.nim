# =======
# Imports
# =======

import os
import parseopt2

import libclang

import "src/header.nim"
import "src/framework.nim"

# =====
# Types
# =====

type SubCommand {.pure.} = enum 
  None,
  Framework,
  Header

# =========
# Functions
# =========

proc progName(): string =
  ## get the program's name
  result = os.extractFilename(os.getAppFilename())

proc usage(command: SubCommand): void =
  ## define the usage for "--help"# define the usage for "--help"
  case command:
  of SubCommand.None: echo("usage: " & progName() & " [--help|-h] [--version] [header|framework] ...")
  of SubCommand.Header: echo("usage: " & progName() & " header --path:<path to a header>")
  of SubCommand.Framework: echo("usage: " & progName() & " framework --path:<path to framework>")

proc versionInfo(): void =
  ## define the version number##
  echo(progName() & " v0.1")
  echo(getCString(getClangVersion()))

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

var working_path: string
var current_command: SubCommand = SubCommand.None

for kind, key, value in parseopt2.getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "version":
      versionInfo()
      quit(QuitSuccess)
    of "help", "h":
      usage(current_command)
      quit(QuitSuccess)
    of "path":
      working_path = value
    else: discard
  of cmdArgument:
    case key:
    of "header":
      current_command = SubCommand.Header
    of "framework":
      current_command = SubCommand.Framework
    of "version":
      versionInfo()
      quit(QuitSuccess)      
    of "help":
      usage(current_command)
      quit(QuitSuccess)
    else: discard
  else: discard

if working_path == nil:
  usage(current_command)
elif os.existsFile(working_path) or os.existsDir(working_path):
  case current_command
  of SubCommand.None:
    usage(current_command)
  of SubCommand.Header:
    parseHeader(working_path)
  of SubCommand.Framework:
    parseFramework(working_path)
else:
  echo("Unable to find file at path: '" & working_path & "'!")
