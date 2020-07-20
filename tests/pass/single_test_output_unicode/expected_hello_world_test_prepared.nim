import streams, unittest_json
import unittest
import hello_world

# version 1.1.0

var strm = newFileStream("trunner_replaces_this_with_path_to_results_json", fmWrite)
let formatter = newJsonOutputFormatter(strm)
addOutputFormatter(formatter)

suite "Hello World":
  test "say hi":
    check hello() == "Hello, World!"

close(formatter)
