# =======
# Imports
# =======

import os

import "language.nim"
import "parser.nim"

# ==========
# Public API
# ==========

proc parseHeader*(header_path: string, input_language: Language): void =
  if not os.existsFile(header_path):
    echo("this is not a file, please specify a file to parse a header")
    return
  parseTranslationUnit(header_path, input_language)

