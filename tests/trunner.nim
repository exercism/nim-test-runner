import critbits, json, os, osproc, strutils, unittest
import runner

let tmpBase = getTempDir()
let outputDir = tmpBase / "nim_test_runner_out/"

for status in ["pass", "fail", "error"]:
  for (kind, path) in walkDir(getAppDir() / status):
    if kind == pcDir:
      for file in walkFiles(path / "*_test.nim"):
        suite status & '/' & path.splitPath().tail:
          let slugUnder = file.splitFile().name[0..^6]
          let slug = slugUnder.replace('_', '-')
          let conf = Conf(slug: slug,
                          inputDir: path & '/',
                          outputDir: outputDir)
          removeDir(conf.outputDir)
          createDir(conf.outputDir)

          let tmpDir = createTmpDir()
          let testPath = prepareFiles(conf, tmpDir)

          test "prepareFiles: Copies the input solution; Returns the test path":
            check tmpDir == tmpBase / "nim_test_runner"
            check testPath == tmpDir / slugUnder & "_test.nim"
            let solNameAndExt = slugUnder & ".nim"
            let tmpSolutionContents = readFile(tmpDir / solNameAndExt)
            let origSolutionContents = readFile(conf.inputDir / solNameAndExt)
            check tmpSolutionContents == origSolutionContents

          if slug == "hello-world" and status == "pass":
            test "prepareFiles: The `hello_world` test file is as expected":
              let f = readFile(conf.inputDir / "expected_hello_world_test_prepared.nim")
              let expectedHelloWorldTest = f.replace(
                "trunner_replaces_this_with_path_to_results_json",
                outputDir / "results.json")
              check readFile(testPath) == expectedHelloWorldTest

          copyFile(getAppDir().parentDir / "src" / "unittest_json.nim",
                   tmpDir / "unittest_json.nim")

          let expectedExitCodeOfRunProc = if status == "pass": 0 else: 1
          test "The `run` proc returns the expected exit code":
            check run(testPath) == expectedExitCodeOfRunProc

          let resultsJson = parseFile(conf.outputDir / "results.json")
          let pathExpectedResultsJson = path / "expected_results.json"
          test "The `results.json` file is as expected":
            if existsFile(pathExpectedResultsJson):
              let expectedResultsJson = parseFile(pathExpectedResultsJson)
              if resultsJson != expectedResultsJson:
                echo "\nresults.json:"
                echo resultsJson.pretty()
                echo "\nexpected_results.json:"
                echo expectedResultsJson.pretty()
                fail()
            else:
              when defined(writeJson):
                writeFile(pathExpectedResultsJson, resultsJson.pretty())
                echo "Wrote: " & pathExpectedResultsJson
              else:
                echo "Missing: " & pathExpectedResultsJson
              fail()

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
