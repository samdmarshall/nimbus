# =======
# Imports
# =======

import os
import strutils

import clang

import "language.nim"
import "serialize.nim"

# ===========
# Private API
# ===========

proc visitChildrenCallback*(cursor: CXCursor, parent: CXCursor, clientData: CXClientData): CXChildVisitResult =
  var context = cast[ptr ParserContext](clientData)
  let source_range: CXSourceRange = getCursorExtent(cursor);
  let location: CXSourceLocation = getRangeStart(source_range);
  var file: CXFile = nil
  getFileLocation(location, addr file, nil, nil, nil)
  let current_file_name = $getCString(getFileName(file))
  let is_in_passed_header = (current_file_name == context.parseFile)
  if is_in_passed_header:
    let name = $getCString(getCursorSpelling(cursor))
    let cursor_kind = getCursorKind(cursor)
    echo(cursor_kind)
    case cursor_kind
    of CXCursor_StructDecl:
      context.cursorType = CursorParseType.Struct
      var names = newSeq[string]()
      var types = newSeq[string]()
      context.cursor.s = StructDeclaration(name: name, memberNames: names, memberTypes: types)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      serializeStruct(context.cursor.s)
    of CXCursor_UnionDecl:
      context.cursorType = CursorParseType.Union
      var names = newSeq[string]()
      var types = newSeq[string]()
      context.cursor.u = UnionDeclaration(name: name, memberNames: names, memberTypes: types)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      serializeUnion(context.cursor.u)
    of CXCursor_EnumDecl:
      context.cursorType = CursorParseType.Enum
      var names = newSeq[string]()
      var values = newSeq[string]()
      context.cursor.e = EnumDeclaration(name: name, memberNames: names, memberValues: values)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      serializeEnum(context.cursor.e)
    of CXCursor_FieldDecl:
      case context.cursorType
      of CursorParseType.Struct:
        context.cursor.s.memberNames.add(name)
      of CursorParseType.Union:
        context.cursor.u.memberNames.add(name)
      else:
        discard
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursor_EnumConstantDecl:
      case context.cursorType
      of CursorParseType.Enum:
        context.cursor.e.memberNames.add(name)
      else:
        discard
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursor_FunctionDecl:
      context.cursorType = CursorParseType.Function
      var names = newSeq[string]()
      var types = newSeq[string]()
      context.cursor.f = FunctionDeclaration(name: name, returnValue: "nil", parameterNames: names, parameterTypes: types)
      discard visitChildren(cursor, visitChildrenCallback, clientData)
      serializeFunction(context.cursor.f)
    of CXCursor_ObjCInterfaceDecl:
      discard
    of CXCursor_ObjCCategoryDecl:
      discard
    of CXCursor_ObjCProtocolDecl:
      discard
    of CXCursor_ObjCInstanceMethodDecl:
      discard
    of CXCursor_ObjCClassMethodDecl:
      discard
    of CXCursor_TypedefDecl:
      discard
    of CXCursor_ParmDecl:
      case context.cursorType
      of CursorParseType.Function:
        context.cursor.f.parameterNames.add(name)
      else:
        discard
      discard visitChildren(cursor, visitChildrenCallback, clientData)
    of CXCursor_TypeRef:
      case context.cursorType
      of CursorParseType.Struct:
        context.cursor.s.memberTypes.add(name)
      of CursorParseType.Union:
        context.cursor.u.memberTypes.add(name)
      of CursorParseType.Function:
        if context.cursor.f.returnValue == "nil":
          context.cursor.f.returnValue = name
        else:
          context.cursor.f.parameterTypes.add(name)
        discard visitChildren(cursor, visitChildrenCallback, clientData)
      else:
        discard
    else:
      discard visitChildren(cursor, visitChildrenCallback, clientData)
  result = CXChildVisit_Continue

# ==========
# Public API
# ==========

proc parseTranslationUnit*(file_path: string, input_language: Language): void =
  case input_language:
  of Language.ObjC:
    write(stdout, "type Id {.importc: \"id\", header: \"<objc/NSObject.h>\", final.} = distinct int" & "\n")
  else:
    discard
  write(stdout, "## " & file_path & "\n")
  let arguments: seq[string] = @["-x", $input_language, "-I/usr/include/", "-I."]
  let args_cstring = allocCStringArray(arguments)
  let index = createIndex(1,1)
  let parameter_count = (arguments.len - 1).cint
  let tu = parseTranslationUnit(index, file_path.cstring, args_cstring, parameter_count, nil, 0, 0)
  var context = ParserContext(parseFile: file_path, cursor: ParseCursor())
  let client_data = CXClientData(addr context)
  let cursor = getTranslationUnitCursor(tu)
  discard visitChildren(cursor, visitChildrenCallback, client_data)

