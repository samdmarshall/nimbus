# =======
# Imports
# =======

import "language.nim"

# ==========
# Public API
# ==========

proc serializeStruct*(s: StructDeclaration): void =
  stdout.write("type " & s.name & "* = object")
  stdout.write("\n")
  for index in 0..<s.memberNames.len:
    let member_name = s.memberNames[index]
    let member_type = s.memberTypes[index]
    stdout.write("  " & member_name & ": " & member_type)
    stdout.write("\n")

proc serializeUnion*(u: UnionDeclaration): void =
  stdout.write("type " & u.name & "* {.union.} = object")
  stdout.write("\n")
  for index in 0..<u.memberNames.len:
    let member_name = u.memberNames[index]
    let member_type = u.memberTypes[index]
    stdout.write("  " & member_name & ": " & member_type)
    stdout.write("\n")

proc serializeEnum*(e: EnumDeclaration): void =
  stdout.write("type " & e.name & "* = enum")
  stdout.write("\n")
  for index in 0..<e.memberNames.len:
    let member_name = e.memberNames[index]
    stdout.write("  " & member_name)
    if index < e.memberValues.len:
      let member_value = e.memberValues[index]
      stdout.write(" = " & member_value)
    stdout.write(",")
    stdout.write("\n")

proc serializeFunction*(f: FunctionDeclaration): void =
  stdout.write("proc " & f.name & "*(")
  for index in 0..<f.parameterNames.len:
    let parameter_name = f.parameterNames[index]
    let parameter_type = f.parameterTypes[index]
    stdout.write(parameter_name & ": " & parameter_type)
    if index < (f.parameterNames.len - 1):
      stdout.write(", ")
  stdout.write("): " & f.returnValue & " {.importc: \""& f.name & "\", noDecl.}")
  stdout.write("\n") 
