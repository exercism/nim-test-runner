import os, osproc, parseopt, strutils, terminal

proc writeHelp =
  echo """Usage:
  runner [slug] [inputDir] [outputDir]

Run the tests for the `slug` exercise in `inputDir` and write `result.json` to
`outputDir`.

Options:
  -h, --help      Print this help message"""
  quit(0)

proc writeErrorMsg(s: string) =
  stdout.styledWrite(fgRed, "Error: ")
  stdout.write(s & "\n\n")
  writeHelp()

type
  Conf* = object
    slug*: string
    inputDir*: string
    outputDir*: string

proc parseCmdLine: Conf =
  ## Checks the command-line arguments and returns them if they are in the
  ## correct format.

  # Use `getopt()` here, not `commandLineParams()`.
  var i = 0
  for kind, key, val in getopt():
    case kind
    of cmdShortOption, cmdLongOption:
      let k = key.toLowerAscii()
      case k
      of "h", "help":
        writeHelp()
      else:
        let prefix = if len(k) == 1: "-" else: "--"
        writeErrorMsg("invalid command line option: '" & prefix & key & "'")
    of cmdArgument:
      case i
      of 0:
        result.slug = key
      of 1:
        result.inputDir = key
      of 2:
        result.outputDir = key
      else:
        writeErrorMsg("too many arguments: '" & key & "'")
      inc(i)
    of cmdEnd: assert(false) # Cannot happen.

  if i == 0:
    writeHelp()
  if result.slug.len == 0 or result.inputDir.len == 0 or result.outputDir.len == 0:
    writeErrorMsg("not enough arguments")
  if result.inputDir[^1] != '/':
    writeErrorMsg("inputDir must end in a trailing slash")
  if result.outputDir[^1] != '/':
    writeErrorMsg("outputDir must end in a trailing slash")
  if not existsDir(result.inputDir):
    writeErrorMsg("the inputDir '" & result.inputDir & "' does not exist")

proc createTmpDir: string =
  ## Returns the path of a temporary directory.
  result = getTempDir() / "nim_test_runner"
  removeDir(result)
  createDir(result)

type
  Paths* = object
    inputSol*: string
    inputTest*: string
    unittestJson*: string
    tmpSol*: string
    tmpTest*: string
    tmpUnittestJson*: string
    outResults*: string

proc getPaths*(conf: Conf): Paths =
  let
    slugUnder = conf.slug.replace("-", "_")
    solName = slugUnder & ".nim"       # e.g. "hello_world.nim"
    testName = slugUnder & "_test.nim" # e.g. "hello_world_test.nim"
    tmpDir = createTmpDir()
  result = Paths(
    inputSol: conf.inputDir / solName,
    inputTest: conf.inputDir / testName,
    unittestJson: getAppDir().parentDir() / "src" / "unittest_json.nim",
    tmpSol: tmpDir / solName,
    tmpTest: tmpDir / testName,
    tmpUnittestJson: tmpDir / "unittest_json.nim",
    outResults: conf.outputDir / "results.json",
  )

proc writeTopLevelErrorJson(path: string, message: string) =
  ## Writes to `path` a JSON file that has a top-level error status, and a
  ## top-level message of `message`.
  let contents = """{"status": "error", "message": """" & message &
                 """", "tests": []}"""
  writeFile(path, contents)

proc copyEditedTest(paths: Paths) =
  ## Reads the student's test file in `paths.inputTest`, adds code so that it
  ## uses our JSON output formatter, and writes the result to `paths.tmpTest`.
  let beforeTests =
    "var strm = newFileStream(\"" & paths.outResults & """", fmWrite)
let formatter = newJsonOutputFormatter(strm)
addOutputFormatter(formatter)

"""
  const afterTests = "\nclose(formatter)\n"

  var isBeforeFirstSuite = true
  var editedTestContents = "import streams, unittest_json\n"

  for line in lines(paths.inputTest):
    if isBeforeFirstSuite and line.startsWith("suite"):
      isBeforeFirstSuite = false
      editedTestContents &= beforeTests
    editedTestContents &= line & '\n'
  editedTestContents &= afterTests
  writeFile(paths.tmpTest, editedTestContents)

proc prepareFiles*(paths: Paths) =
  ## Writes the necessary files to the directory that we use to run the tests.
  createDir(paths.outResults.parentDir())
  copyFile(paths.inputSol, paths.tmpSol)
  copyEditedTest(paths)
  copyFile(paths.unittestJson, paths.tmpUnittestJson)

proc run*(paths: Paths): int =
  ## Compiles and runs the file in `testPath`. Returns its exit code.
  let (compMsgs, exitCode1) = execCmdEx("nim c --styleCheck:hint " &
                                        "--skipUserCfg:on --verbosity:0 " &
                                        "--hint[Processing]:off " &
                                        paths.tmpTest)

  if exitCode1 != 0:
    writeTopLevelErrorJson(paths.outResults, compMsgs)
    return exitCode1

  let compiledTestPath = paths.tmpTest[0..^5] # Remove `.nim` file extension
  let (_, exitCode2) = execCmdEx(compiledTestPath)
  result = exitCode2

when isMainModule:
  let conf = parseCmdLine()
  let paths = getPaths(conf)
  prepareFiles(paths)
  discard run(paths)
