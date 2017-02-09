# =======
# Imports
# =======

import os

import "parser.nim"

# ==========
# Public API
# ==========

proc parseHeader*(header_path: string): void =
  if not os.existsFile(header_path):
    echo("this is not a file, please specify a file to parse a header")
    return

  
