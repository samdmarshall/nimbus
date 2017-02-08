import os
import streams
import parsexml
import parseopt2

type ObjCType = enum
  ObjCType_char,
  ObjCType_int,
  ObjCType_long,
  ObjCType_longlong,
  ObjCType_unsignedchar,
  ObjCType_unsignedint,
  ObjCType_unsignedlong,
  ObjCType_unsignedlonglong,
  ObjCType_float,
  ObjCType_double,
  ObjCType_bool,
  ObjCType_void,
  ObjCType_cstring,
  ObjCType_object,
  ObjCType_class,
  ObjCType_selector,
  ObjCType_array,
  ObjCType_struct,
  ObjCType_union,
  ObjCType_bitfield,
  ObjCType_pointer,
  ObjCType_functionpointer

# global state
var output_file_path: string
var bridge_file_path: string
var umbrella_header_path: string
var linker_flags: string

# =========
# functions
# =========

proc decodeObjCType(type_string: string): string =
  let first_character = type_string[0]
  case first_character
  of 'c':
    return "int8"
  of 'C':
    return "uint8"
  of 'i':
    return "int"
  of 's':
    return "cshort"
  of 'l':
    return "int32"
  of 'q':
    return "int64"
  of '@':
    return "id"
  else:
    return ""

proc parseStruct(parser: var XmlParser, output: File): void =
  discard

proc parseCFType(parser: var XmlParser, output: File): void =
  discard

proc parseOpaque(parser: var XmlParser, output: File): void =
  discard

proc parseConstant(parser: var XmlParser, output: File): void =
  write(output, "const ")
  while true:
    case parser.kind
    of xmlAttribute:
      case parser.attrKey()
      of "name":
        write(output, parser.attrValue())
        write(output, "*")
      of "type":
        write(output, ":")
        write(output, decodeObjCType(parser.attrValue()))
      else: discard
    of xmlElementClose:
      break
    else: discard
    parser.next()
  write(output, " {.header:\"" & umbrella_header_path & "\", importobjc.}")
  write(output, "\n")

# ================
# Main Entry Point
# ================

var output: File

for kind, key, value in parseopt2.getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h": discard
    of "version", "v": discard
    of "output", "o":
      output_file_path = value
    of "umbrella", "u":
      umbrella_header_path = value
    of "linker-flags", "l":
      linker_flags = value
    else: discard
  of cmdArgument:
    bridge_file_path = key
  else: discard

if bridge_file_path == nil:
  echo("please supply the path to the bridging xml file!")
  quit(QuitFailure)

if umbrella_header_path == nil:
  echo("please supply the path to the umbrella header!")
  quit(QuitFailure)

if not os.existsFile(output_file_path):
  output = stdout
else:
  output = open(output_file_path, fmReadWrite)

if not (linker_flags == nil):
  write(output, "{.passL: \"" & linker_flags & "\".}")

let bridge_file = streams.newFileStream(bridge_file_path, fmRead)
var bridge_parser: XmlParser
open(bridge_parser, bridge_file, bridge_file_path)

while true:
  bridge_parser.next()
  case bridge_parser.kind
  of xmlElementOpen:
    case bridge_parser.elementName()
    of "signatures":
      bridge_parser.next()
    of "depends_on":
      bridge_parser.next()
    of "struct":
      parseStruct(bridge_parser, output)
    of "cftype":
      parseCFType(bridge_parser, output)
    of "opaque":
      parseOpaque(bridge_parser, output)
    of "constant":
      parseConstant(bridge_parser, output)
    of "string_constant": discard
    of "enum": discard
    of "function": discard
    of "function_alias": discard
    of "class": discard
    of "informal_protocol": discard
    else: discard
  of xmlEof: break
  else: discard


# finish up and close the files
bridge_parser.close()
if not os.existsFile(output_file_path):
  output.close()
