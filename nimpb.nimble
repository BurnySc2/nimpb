version = "0.1.0"
author = "Oskari Timperi"
description = "protobuf library for Nim"
license = "MIT"

skipDirs = @["examples", "tests"]

bin = @["nimpb/compiler/compiler"]

requires "nim >= 0.18.0"
