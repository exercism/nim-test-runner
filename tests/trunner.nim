import json, os, strutils, unittest
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
                writeFile(pathExpectedResultsJson, resultsJson.pretty() & '\n')
                echo "Wrote: " & pathExpectedResultsJson
              else:
                echo "Missing: " & pathExpectedResultsJson
              fail()

when defined(repoSolutions):
  import trunner_repo_solutions
  repoSolutions()
