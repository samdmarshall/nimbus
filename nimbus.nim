# =======
# Imports
# =======

import os
import parseopt2

import libclang

import "src/language.nim"
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
  of SubCommand.None: echo("usage: " & progName() & " [--help|-h] [--version] --language:[c|cpp|objc|objcpp] [header|framework] ...")
  of SubCommand.Header: echo("usage: " & progName() & " header --language:[c|cpp|objc|objcpp] --path:<path to a header>")
  of SubCommand.Framework: echo("usage: " & progName() & " framework --language:[c|cpp|objc|objcpp] --path:<path to framework>")

proc versionInfo(): void =
  ## define the version number
  let clang_version = getCString(getClangVersion())
  echo(progName() & " v0.1" & " -- using " & $clang_version)

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

var working_path: string
var current_command: SubCommand = SubCommand.None
var input_language: Language = Language.None

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
    of "language":
      case value
      of "c":
        input_language = Language.C
      of "cpp":
        input_language = Language.Cpp
      of "objc":
        input_language = Language.ObjC
      of "objcpp":
        input_language = Language.ObjCpp
      else:
        echo("invalid language input, please use 'c', 'cpp', 'objc', or 'objcpp'")
        quit(QuitFailure)
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

if working_path == nil or input_language == Language.None:
  usage(current_command)
elif os.existsFile(working_path) or os.existsDir(working_path):
  case current_command
  of SubCommand.None:
    usage(current_command)
  of SubCommand.Header:
    parseHeader(working_path, input_language)
  of SubCommand.Framework:
    parseFramework(working_path, input_language)
else:
  echo("Unable to find file at path: '" & working_path & "'!")
