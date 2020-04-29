# Package
version       = "0.1.0"
author        = "Samantha Marshall"
description   = "nimbus is a tool to translate C and Objective-C headers into nim."
license       = "MIT"

srcDir        = "src/"

bin           = @["nimbus"]
binDir        = "build/"

# Dependencies
requires "nim >= 1.0.0"
requires "https://github.com/samdmarshall/libclang-nim"
