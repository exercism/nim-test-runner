import std/unittest
import identity

# version 1.1.0

suite "Hello World":
  test "say hi!":
    check hello() == "Hello, World!"
