# Package
version       = "0.1"
author        = "Samantha Marshall"
description   = "nimbus is a tool to translate C and Objective-C headers into nim."
license       = "MIT"

srcDir = "src/"

bin = @["nimbus"]

skipExt = @["nim"]

# Deps
requires "nim >= 0.14.0"
requires "libclang >= 0.1.0"
