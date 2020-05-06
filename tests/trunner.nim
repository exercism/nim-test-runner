import critbits, os, osproc, strscans, strutils, unittest
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

let expectedTestFile = """import streams
import unittest
import hello_world

# version 1.1.0

var strm = newFileStream("""" & outputDir / "results.xml" & """", fmWrite)
let formatter = newJUnitOutputFormatter(strm)
addOutputFormatter(formatter)

suite "Hello World":
  test "say hi":
    check hello() == "Hello, World!"

close(formatter)
"""

const expectedXml = """<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
	<testsuite name="Hello World">
		<testcase name="say hi" time="0.00000310">
		</testcase>
	</testsuite>
</testsuites>
""".splitLines()

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
  test "The `run` proc returns an exit code of 0":
    check run(testPath) == 0

  test "The xml output file is as expected":
    let xmlContents = readFile(conf.outputDir / "results.xml").splitLines()
    check xmlContents.len == 8
    for i in 0 .. expectedXml.high:
      if i != 3:
        check xmlContents[i] == expectedXml[i]
    var n: float
    check xmlContents[3].scanf("""		<testcase name="say hi" time="$f">""", n)

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
      discard run(testPath)
      let xmlPath = conf.outputDir / "results.xml"
      let xmlContents = readFile(xmlPath)
      check:
        xmlContents.len > 0
        "failure" notin xmlContents
      moveFile(xmlPath, conf.outputDir / slugUnder & ".xml")
