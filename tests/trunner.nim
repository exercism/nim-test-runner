import critbits, json, os, osproc, strutils, unittest
import runner

let tmpBase = getTempDir()
let outputDir = tmpBase / "nim_test_runner_out/"

let conf = Conf(slug: "hello-world",
                inputDir: tmpBase / "exercises" / "hello-world/",
                outputDir: outputDir)

removeDir(conf.inputDir)
removeDir(conf.outputDir)
createDir(conf.inputDir)
createDir(conf.outputDir)

const helloWorldSolution = """proc hello*: string = "Hello, World!""""
const helloWorldTest = """import unittest
import hello_world

# version 1.1.0

suite "Hello World":
  test "say hi":
    check hello() == "Hello, World!"
"""

writeFile(conf.inputDir / "hello_world.nim", helloWorldSolution)
writeFile(conf.inputDir / "hello_world_test.nim", helloWorldTest)

let tmpDir = createTmpDir()
let testPath = prepareFiles(conf, tmpDir)

let expectedTestFile = """import streams, unittest_json
import unittest
import hello_world

# version 1.1.0

var strm = newFileStream("""" & outputDir / "results.json" & """", fmWrite)
let formatter = newJsonOutputFormatter(strm)
addOutputFormatter(formatter)

suite "Hello World":
  test "say hi":
    check hello() == "Hello, World!"

close(formatter)
"""

let expectedJsonContents = """{
  "status": "pass",
  "tests": [
    {
      "name": "say hi",
      "status": "pass",
      "output": ""
    }
  ]
}""".parseJson()


suite "prepareFiles":
  let expectedTmpDir = tmpBase / "nim_test_runner"
  test "tmpDir":
    check tmpDir == expectedTmpDir

  test "testPath":
    check testPath == expectedTmpDir / "hello_world_test.nim"

  test "The solution file was copied unchanged":
    check readFile(expectedTmpDir / "hello_world.nim") == helloWorldSolution

  test "The test file was correctly prepared":
    check readFile(testPath) == expectedTestFile

suite "run":
  copyFile(getAppDir().parentDir / "src" / "unittest_json.nim", tmpDir / "unittest_json.nim")
  test "The `run` proc returns an exit code of 0":
    check run(testPath) == 0

  test "The `results.json` file is as expected":
    let jsonContents = parseFile(conf.outputDir / "results.json")
    check jsonContents == expectedJsonContents

suite "run all":
  let baseDir = getTempDir() / "exercism" / "nim"
  if not existsDir(baseDir):
    let cmd = "git clone --depth 1 https://github.com/exercism/nim.git " &
              baseDir
    let errC = execCmd(cmd)
    if errC != 0:
      echo "Error: failed when running `git clone`"
      removeDir(baseDir)
      quit(1)

  var slugs: CritBitTree[void]

  let exercisesDir = baseDir / "exercises"
  for (_, dir) in walkDir(exercisesDir):
    slugs.incl(dir.splitPath().tail)

  # Run the tests in alphabetical order
  for slug in slugs:
    test slug:
      let slugDir = exercisesDir / slug
      let slugUnder = slug.replace('-', '_')
      let exampleContents = readFile(slugDir / "example.nim")
      let solutionPath = slugDir / slugUnder & ".nim"
      writeFile(solutionPath, exampleContents)

      let conf = Conf(slug: slug,
                      inputDir: slugDir,
                      outputDir: outputDir)

      let tmpDir = createTmpDir()
      let testPath = prepareFiles(conf, tmpDir)
      copyFile(getAppDir().parentDir / "src" / "unittest_json.nim", tmpDir / "unittest_json.nim")
      discard run(testPath)
      let resultsPath = conf.outputDir / "results.json"
      let j = parseFile(resultsPath)
      for test in j["tests"]:
        check:
          test["name"].getStr().len > 0
          test["output"].getStr().len == 0
          test["status"].getStr() == "pass"
          test.len == 3
      check:
        j["status"].getStr() == "pass"
      moveFile(resultsPath, conf.outputDir / slugUnder & ".json")
