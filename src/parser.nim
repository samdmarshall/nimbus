# =======
# Imports
# =======

import os

import libclang

import "language.nim"

# ==========
# Public API
# ==========

proc parseTranslationUnit*(file_path: string, input_language: Language): void =
  let arguments: seq[string] = @["-x", $input_language, "-I/usr/include/", "-I."]
  let args_cstring = allocCStringArray(arguments)
  let index = libclang.createIndex(1,1)
  let parameter_count = (arguments.len - 1).cint
  let tu = libclang.parseTranslationUnit(index, file_path.cstring, args_cstring, parameter_count, nil, 0, 0)
  echo(repr(tu))
