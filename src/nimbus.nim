# =======
# Imports
# =======

# Standard Library Imports
import os
import parseopt

# Third Party Package Imports
import clang

# Package Imports
import "language.nim"
import "header.nim"
import "framework.nim"

# =====
# Types
# =====

type SubCommand {.pure.} = enum
  None,
  Version,
  Help,
  Framework,
  Header

# =========
# Functions
# =========

proc progName(): string =
  ## get the program's name
  result = extractFilename(getAppFilename())

proc versionInfo(): void =
  ## define the version number
  let clang_version = getCString(getClangVersion())
  echo(progName() & " v0.1" & " -- using " & $clang_version)

proc usage(command: SubCommand): void =
  ## define the usage for "--help"# define the usage for "--help"
  case command:
  of SubCommand.None, SubCommand.Help:
    echo("usage: " & progName() & " [-h|--help] [-v|--version] --language:[c|cpp|objc|objcpp] [header|framework] ...")
  of SubCommand.Version:
    versionInfo()
  of SubCommand.Header:
    echo("usage: " & progName() & " header --language:[c|objc] --path:<path to a header>")
  of SubCommand.Framework:
    echo("usage: " & progName() & " framework --language:[c|objc] --path:<path to framework>")

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

proc main() =
  var working_path: string
  var current_command = SubCommand.None
  var input_language = Language.None
  var parser = initOptParser()

  for kind, key, value in parser.getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case key
      of "version", "v":
        current_command = SubCommand.Version
      of "help", "h":
        current_command = SubCommand.Help
      of "path":
        working_path = value
      of "language":
        case value
        of "c":
          input_language = Language.C
        of "objc":
          input_language = Language.ObjC
        else:
          echo("invalid language input, please use 'c' or 'objc'")
          quit(QuitFailure)
      else:
        discard
    of cmdArgument:
      case key:
      of "header":
        current_command = SubCommand.Header
      of "framework":
        current_command = SubCommand.Framework
      of "version":
        current_command = SubCommand.Version
      of "help":
        current_command = SubCommand.Help
      else:
        discard
    else:
      discard

  if working_path == "" or input_language == Language.None:
    usage(current_command)
  elif existsFile(working_path) or existsDir(working_path):
    case current_command
    of SubCommand.None, SubCommand.Help:
      usage(current_command)
    of SubCommand.Version:
      versionInfo()
    of SubCommand.Header:
      parseHeader(working_path, input_language)
    of SubCommand.Framework:
      parseFramework(working_path, input_language)
  else:
    echo("Unable to find file at path: '" & working_path & "'!")
    quit(QuitFailure)


when isMainModule:
  main()