import os, osproc, parseopt, streams, strutils, terminal

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

proc createTmpDir*: string =
  ## Returns the path of a temporary directory.
  result = getTempDir() / "nim_test_runner"
  removeDir(result)
  createDir(result)

proc prepareFiles*(conf: Conf, tmpDir: string): string =
  ## Returns the path of the edited test file.
  let
    slugUnder = conf.slug.replace("-", "_")
    solName = slugUnder & ".nim" # e.g. "hello_world.nim"
    testName = slugUnder & "_test.nim" # e.g. "hello_world_test.nim"
  result = tmpDir / testName
  copyFile(conf.inputDir / solName, tmpDir / solName)

  let resultsJsonPath = conf.outputDir / "results.json"
  let beforeTests = "var strm = newFileStream(\"" & resultsJsonPath & """", fmWrite)
let formatter = newJsonOutputFormatter(strm)
addOutputFormatter(formatter)

injectCode """" & slugUnder & """.nim":
  proc debug(x: varargs[string, `$`]) =
    for i in x:
      writeFile("""" & conf.outputDir & """output.txt", i)

"""
  const afterTests = "\nclose(formatter)\n"

  var isBeforeFirstSuite = true
  var editedTestContents = "import streams, unittest_json, code_injection\n"

  for line in lines(conf.inputDir / testName):
    if isBeforeFirstSuite and line.startsWith("suite"):
      isBeforeFirstSuite = false
      editedTestContents &= beforeTests
    elif slugUnder in line: # all nim exercises import the solution as the only module on the line
      continue
    editedTestContents &= line & '\n'
  editedTestContents &= afterTests
  echo editedTestContents
  writeFile(result, editedTestContents)
  copyFile(getAppDir().parentDir() / "src" / "unittest_json.nim",
           tmpDir / "unittest_json.nim")
  copyFile(getAppDir().parentDir() / "src" / "code_injection.nim",
           tmpDir / "code_injection.nim")
  createDir(conf.outputDir)

proc run*(testPath: string): int =
  ## Compiles and runs the file in `testPath`. Returns its exit code.
  # Use `startProcess` here, not `execCmd`.
  result = -1

  let args = @["c", "-r", "--styleCheck:hint", "--skipUserCfg:on",
               "--verbosity:0", "--hint[Processing]:off", testPath]

  var
    p = startProcess("nim", args = args, options = {poStdErrToStdOut, poUsePath})
    outp = outputStream(p)
    line = newStringOfCap(120).TaintedString

  while true:
    if outp.readLine(line):
      stdout.writeLine(line)
    else:
      result = peekExitCode(p)
      if result != -1:
        break
  close(p)

when isMainModule:
  let conf = parseCmdLine()
  let tmpDir = createTmpDir()
  let testPath = prepareFiles(conf, tmpDir)
  discard run(testPath)
