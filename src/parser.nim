# =======
# Imports
# =======

import os
import strutils

import libclang

import "language.nim"

# ===========
# Private API
# ===========

proc visitChildrenCallback(cursor: CXCursor, parent: CXCursor, clientData: CXClientData): CXChildVisitResult {.cdecl.} =
  let file_path = cast[ptr cstring](clientData)[]
  let source_range: CXSourceRange = libclang.getCursorExtent(cursor);
  let location: CXSourceLocation = libclang.getRangeStart(source_range);
  var file: CXFile
  libclang.getFileLocation(location, addr file, nil, nil, nil)
  let is_in_passed_header = ($libclang.getCString(libclang.getFileName(file)) == $file_path)
  if is_in_passed_header:
    let name = $libclang.getCString(getCursorSpelling(cursor))
    case libclang.getCursorKind(cursor)
    of CXCursorKind.StructDecl:
      echo("type " & name & "* = object")
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.UnionDecl:
      echo("type " & name & "* {.union.} = object")
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.EnumDecl:
      echo("type " & name & "* = enum")
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.FieldDecl:
      echo("  " & name)
      discard
    of CXCursorKind.EnumConstantDecl:
      echo("  " & name & ",")
      discard
    of CXCursorKind.FunctionDecl:
      echo("proc " & name & "* = ")
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.ObjCInterfaceDecl:
      echo("type " & name & "* = Id")
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.ObjCCategoryDecl:
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.ObjCProtocolDecl:
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.ObjCInstanceMethodDecl:
      let argument_count = strutils.count(name, ":")
      let replaced_method_string = strutils.replace(name, ":", "_")
      let method_string = if strutils.endsWith(replaced_method_string, "_"): replaced_method_string[0 .. replaced_method_string.len - 2]
                          else: replaced_method_string
      #echo("proc " & method_string & "*(self: object")
      if argument_count > 0:
        for index in 0..argument_count:
          discard visitChildren(cursor, visitChildrenCallback, clientData)
      #echo(") {.importobjc: \"" & method_string & "\", noDecl.}")
    of CXCursorKind.ObjCClassMethodDecl: discard
    of CXCursorKind.TypedefDecl: discard
    of CXCursorKind.ParmDecl:
      #echo(name)
      discard
    else: discard
  result = CXChildVisitResult.Continue

# ==========
# Public API
# ==========

proc parseTranslationUnit*(file_path: string, input_language: Language): void =
  case input_language:
  of Language.ObjC:
    echo("type Id {.importc: \"id\", header: \"<objc/NSObject.h>\", final.} = distinct int")
  else:
    discard
  let arguments: seq[string] = @["-x", $input_language, "-I/usr/include/", "-I."]
  let args_cstring = allocCStringArray(arguments)
  let index = libclang.createIndex(1,1)
  let parameter_count = (arguments.len - 1).cint
  let tu = libclang.parseTranslationUnit(index, file_path.cstring, args_cstring, parameter_count, nil, 0, 0)
  var file_path_cstring = file_path.cstring
  let client_data = CXClientData(addr file_path_cstring)
  let cursor = libclang.getTranslationUnitCursor(tu)
  discard libclang.visitChildren(cursor, visitChildrenCallback, client_data)
    
