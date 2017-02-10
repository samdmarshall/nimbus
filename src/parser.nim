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

proc writeType(context: ptr ParserContext): void = 
  case context.cursorType
  of CursorParseType.Struct:
    write(stdout, "type " & context.cursor.s.name & "* = object")
    write(stdout, "\n")
    for index in 0..<context.cursor.s.memberNames.len:
      let member_name = context.cursor.s.memberNames[index]
      let member_type = context.cursor.s.memberTypes[index]
      write(stdout, "  " & member_name & ": " & member_type)
      write(stdout, "\n")
  of CursorParseType.Union:
    write(stdout, "type " & context.cursor.u.name & "* {.union.} = object")
    write(stdout, "\n")
    for index in 0..<context.cursor.u.memberNames.len:
      let member_name = context.cursor.u.memberNames[index]
      let member_type = context.cursor.u.memberTypes[index]
      write(stdout, "  " & member_name & ": " & member_type)
      write(stdout, "\n")
  of CursorParseType.Enum:
    write(stdout, "type " & context.cursor.e.name & "* = enum")
    write(stdout, "\n")
    for index in 0..<context.cursor.e.memberNames.len:
      let member_name = context.cursor.e.memberNames[index]
      write(stdout, "  " & member_name)
      if index < context.cursor.e.memberValues.len:
        let member_value = context.cursor.e.memberValues[index]
        write(stdout, " = " & member_value)
      write(stdout, ",")
      write(stdout, "\n")
  of CursorParseType.Function:
    discard
  else:
    discard

proc visitChildrenCallback(cursor: CXCursor, parent: CXCursor, clientData: CXClientData): CXChildVisitResult {.cdecl.} =
  var context = cast[ptr ParserContext](clientData)
  let source_range: CXSourceRange = libclang.getCursorExtent(cursor);
  let location: CXSourceLocation = libclang.getRangeStart(source_range);
  var file: CXFile = nil
  libclang.getFileLocation(location, addr file, nil, nil, nil)
  let current_file_name = $libclang.getCString(libclang.getFileName(file))
  let is_in_passed_header = (current_file_name == context.parseFile)
  if is_in_passed_header:
    let name = $libclang.getCString(getCursorSpelling(cursor))
    case libclang.getCursorKind(cursor)
    of CXCursorKind.StructDecl:
      context.cursorType = CursorParseType.Struct
      var names = newSeq[string]()
      var types = newSeq[string]()
      context.cursor.s = StructDeclaration(name: name, memberNames: names, memberTypes: types)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      writeType(context)
    of CXCursorKind.UnionDecl:
      context.cursorType = CursorParseType.Union
      var names = newSeq[string]()
      var types = newSeq[string]()
      context.cursor.u = UnionDeclaration(name: name, memberNames: names, memberTypes: types)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      writeType(context)
    of CXCursorKind.EnumDecl:
      context.cursorType = CursorParseType.Enum
      var names = newSeq[string]()
      var values = newSeq[string]()
      context.cursor.e = EnumDeclaration(name: name, memberNames: names, memberValues: values)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      writeType(context)
    of CXCursorKind.FieldDecl:
      case context.cursorType
      of CursorParseType.Struct:
        context.cursor.s.memberNames.add(name)
      of CursorParseType.Union:
        context.cursor.u.memberNames.add(name)
      else:
        discard
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.EnumConstantDecl:
      case context.cursorType
      of CursorParseType.Enum:
        context.cursor.e.memberNames.add(name)
      else:
        discard
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.FunctionDecl:
      context.cursorType = CursorParseType.Function
      var names = newSeq[string]()
      var types = newSeq[string]()
      context.cursor.f = FunctionDeclaration(name: name, returnValue: nil, parameterNames: names, parameterTypes: types)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      writeType(context)
    of CXCursorKind.ObjCInterfaceDecl:
      discard
    of CXCursorKind.ObjCCategoryDecl:
      discard
    of CXCursorKind.ObjCProtocolDecl:
      discard
    of CXCursorKind.ObjCInstanceMethodDecl:
      discard
    of CXCursorKind.ObjCClassMethodDecl: discard
    of CXCursorKind.TypedefDecl: discard
    of CXCursorKind.ParmDecl:
      case context.cursorType
      of CursorParseType.Function:
        context.cursor.f.parameterNames.add(name)
      else:
        discard
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursorKind.TypeRef:
      case context.cursorType
      of CursorParseType.Struct:
        context.cursor.s.memberTypes.add(name)
      of CursorParseType.Union:
        context.cursor.u.memberTypes.add(name)
      else:
        discard
    else:
      discard
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
  var context = ParserContext(parseFile: file_path, cursor: ParseCursor())
  let client_data = CXClientData(addr context)
  let cursor = libclang.getTranslationUnitCursor(tu)
  discard libclang.visitChildren(cursor, visitChildrenCallback, client_data)
    
