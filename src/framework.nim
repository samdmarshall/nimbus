# =======
# Imports
# =======

import os

import "language.nim"
import "header.nim"

# ==========
# Public API
# ==========

proc parseFramework*(framework_path: string, input_language: Language): void =
  if not os.existsDir(framework_path):
    echo("this is not a directory, please specify a \".framework\", or a directory of headers")
    return
  let public_headers_path = os.joinPath(framework_path, "Headers/")
  let private_headers_path = os.joinPath(framework_path, "PrivateHeaders/")
  for file in os.walkDirRec(public_headers_path):
    parseHeader(file, input_language)
  for file in os.walkDirRec(private_headers_path):
    parseHeader(file, input_language)
    
