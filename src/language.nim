# =====
# Types
# =====

type Language* {.pure.} = enum 
  None = "",
  C = "c",
  ObjC = "objective-c",

type CursorParseType* {.pure.} = enum
  Struct,
  Union,
  Enum,
  Function,

type StructDeclaration* = object
  name*: string
  memberNames*: seq[string]
  memberTypes*: seq[string]

type UnionDeclaration* = object
  name*: string
  memberNames*: seq[string]
  memberTypes*: seq[string]

type EnumDeclaration* = object
  name*: string
  memberNames*: seq[string]
  memberValues*: seq[string]

type FunctionDeclaration* = object
  name*: string
  returnValue*: string
  parameterNames*: seq[string]
  parameterTypes*: seq[string]

type ParseCursor* = object
  s*: StructDeclaration
  u*: UnionDeclaration
  e*: EnumDeclaration
  f*: FunctionDeclaration

type ParserContext* = object
  parseFile*: string
  cursorType*: CursorParseType
  cursor*: ParseCursor
