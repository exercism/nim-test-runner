import json, os, strutils, unittest
import runner

let tmpBase = getTempDir()
let expectedTmpDir = tmpBase / "nim_test_runner"
let outputDir = tmpBase / "nim_test_runner_out/"
const testPrefix = "test_"

for status in ["pass", "fail", "error"]:
  for (kind, path) in walkDir(getAppDir() / status):
    if kind == pcDir:
      for file in walkFiles(path / testPrefix & "*.nim"):
        suite status & '/' & path.splitPath().tail:
          let slugUnder = file.splitFile().name[testPrefix.len .. ^1]
          let slug = slugUnder.replace('_', '-')
          let conf = Conf(slug: slug,
                          inputDir: path & '/',
                          outputDir: outputDir)
          removeDir(conf.outputDir)
          createDir(conf.outputDir)

          let paths = getPaths(conf)
          test "getPaths: The test path is as expected":
            check paths.tmpTest == expectedTmpDir / "test_" & slugUnder & ".nim"

          prepareFiles(paths)
          test "prepareFiles: Copies the input solution":
            check readFile(paths.tmpSol) == readFile(paths.inputSol)

          if slug == "hello-world" and status == "pass":
            test "prepareFiles: The `hello_world` test file is as expected":
              let f = readFile(conf.inputDir / "expected_test_hello_world_prepared.nim")
              let expectedHelloWorldTest = f.replace(
                "trunner_replaces_this_with_path_to_results_json",
                paths.outResults)
              check readFile(paths.tmpTest) == expectedHelloWorldTest

          let expectedExitCodeOfRunProc = if status == "pass": 0 else: 1
          test "The `run` proc returns the expected exit code":
            check run(paths) == expectedExitCodeOfRunProc

          let resultsJson = parseFile(paths.outResults)
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
