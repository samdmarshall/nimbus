# =======
# Imports
# =======

import "language.nim"

# ==========
# Public API
# ==========

proc serializeStruct*(s: StructDeclaration): void =
  write(stdout, "type " & s.name & "* = object")
  write(stdout, "\n")
  for index in 0..<s.memberNames.len:
    let member_name = s.memberNames[index]
    let member_type = s.memberTypes[index]
    write(stdout, "  " & member_name & ": " & member_type)
    write(stdout, "\n")

proc serializeUnion*(u: UnionDeclaration): void =
  write(stdout, "type " & u.name & "* {.union.} = object")
  write(stdout, "\n")
  for index in 0..<u.memberNames.len:
    let member_name = u.memberNames[index]
    let member_type = u.memberTypes[index]
    write(stdout, "  " & member_name & ": " & member_type)
    write(stdout, "\n")

proc serializeEnum*(e: EnumDeclaration): void =
  write(stdout, "type " & e.name & "* = enum")
  write(stdout, "\n")
  for index in 0..<e.memberNames.len:
    let member_name = e.memberNames[index]
    write(stdout, "  " & member_name)
    if index < e.memberValues.len:
      let member_value = e.memberValues[index]
      write(stdout, " = " & member_value)
    write(stdout, ",")
    write(stdout, "\n")

