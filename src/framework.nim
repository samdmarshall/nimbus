# =======
# Imports
# =======

import os

import "language.nim"
import "parser.nim"

# ==========
# Public API
# ==========

proc parseFramework*(framework_path: string, input_language: Language): void =
  if not os.existsDir(framework_path):
    echo("this is not a directory, please specify a \".framework\", or a directory of headers")
    return
  
    
