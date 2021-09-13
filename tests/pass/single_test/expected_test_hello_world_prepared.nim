import std/streams
import unittest_json
import std/unittest
import hello_world

# version 1.1.0

var strm = newFileStream("trunner_replaces_this_with_path_to_results_json", fmWrite)
let formatter = newJsonOutputFormatter(strm)
addOutputFormatter(formatter)

template test(name, body: untyped) {.dirty.} =
  testWrapper name:
    body

suite "Hello World":
  test "say hi!":
    check hello() == "Hello, World!"

close(formatter)
