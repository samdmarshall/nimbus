# =======
# Imports
# =======

import os

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
  if is_in_passed_header == true:
    case libclang.getCursorKind(cursor)
    of CXCursorKind.StructDecl: discard
    of CXCursorKind.UnionDecl: discard
    of CXCursorKind.EnumDecl: discard
    of CXCursorKind.FieldDecl: discard
    of CXCursorKind.EnumConstantDecl: discard
    of CXCursorKind.FunctionDecl: discard
    of CXCursorKind.ObjCInterfaceDecl:
      echo($libclang.getCString(getCursorSpelling(cursor)))
    of CXCursorKind.ObjCCategoryDecl: discard
    of CXCursorKind.ObjCProtocolDecl: discard
    else: discard
  discard visitChildren(cursor, visitChildrenCallback, clientData)
  result = CXChildVisitResult.Continue

# ==========
# Public API
# ==========

proc parseTranslationUnit*(file_path: string, input_language: Language): void =
  let arguments: seq[string] = @["-x", $input_language, "-I/usr/include/", "-I."]
  let args_cstring = allocCStringArray(arguments)
  let index = libclang.createIndex(1,1)
  let parameter_count = (arguments.len - 1).cint
  let tu = libclang.parseTranslationUnit(index, file_path.cstring, args_cstring, parameter_count, nil, 0, 0)
  var file_path_cstring = file_path.cstring
  let client_data = CXClientData((addr file_path_cstring))
  let cursor = libclang.getTranslationUnitCursor(tu)
  discard libclang.visitChildren(cursor, visitChildrenCallback, client_data)
    
