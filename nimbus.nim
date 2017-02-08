import os
import streams
import parsexml
import parseopt2



# ================
# Main Entry Point
# ================

var bridge_file_path: string

for kind, key, value in parseopt2.getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h": discard
    of "version", "v": discard
    of "output", "o": discard
    else: discard
  of cmdArgument:
    bridge_file_path = key
  else: discard

let bridge_file = streams.newFileStream(bridge_file_path, fmRead)
var bridge_parser: XmlParser
open(bridge_parser, bridge_file, bridge_file_path)

while true:
  bridge_parser.next()
  case bridge_parser.kind
  of xmlElementOpen:
    case bridge_parser.elementName()
    of "signatures": discard
    of "depends_on": discard
    of "struct": discard
    of "cftype": discard
    of "opaque": discard
    of "constant": discard
    of "string_constant": discard
    of "enum": discard
    of "function": discard
    of "function_alias": discard
    of "class": discard
    of "informal_protocol": discard
    else: discard
  of xmlEof: break
  else: discard

bridge_parser.close()
