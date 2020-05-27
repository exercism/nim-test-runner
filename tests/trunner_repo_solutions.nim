import critbits, json, os, osproc, strutils, unittest
import runner

proc repoSolutions* =
  let tmpBase = getTempDir()
  let outputDir = tmpBase / "nim_test_runner_out/"

  suite "Run test-runner on the exercises from `exercism/nim`":
    let baseDir = getTempDir() / "exercism-nim"
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

when isMainModule:
  repoSolutions()
