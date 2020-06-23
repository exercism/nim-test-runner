## An extension of the ``unittest.nim`` library to output json for Exercism v3

import json, streams, strformat, unittest

type
  JsonTestStatus = enum
    PASS = "pass",
    FAIL = "fail",
    ERROR = "error"

  JsonTestResult = object
    name: string
    case status: JsonTestStatus
    of FAIL, ERROR:
      message: string
    of PASS:
      discard
    output: string

  ResultJson = ref object
    case status: JsonTestStatus
    of ERROR:
      message: string
    of PASS, FAIL:
      discard
    tests: seq[JsonTestResult]

  JsonOutputFormatter = ref object of OutputFormatter
    stream: Stream
    testErrors: seq[string]
    testStackTrace: string
    result: ResultJson

proc newJsonOutputFormatter*(stream: Stream): <//>JsonOutputFormatter =
  ## Creates a formatter that writes report to the specified stream in
  ## JSON format.
  ## The ``stream`` is NOT closed automatically when the test are finished,
  ## because the formatter has no way to know when all tests are finished.
  ## You should invoke formatter.close() to finalize the report.
  result = JsonOutputFormatter(
    stream: stream,
    testErrors: @[],
    testStackTrace: "",
    result: ResultJson(tests: @[], status: PASS)
  )

proc close*(formatter: JsonOutputFormatter) =
  ## Completes the report and closes the underlying stream.
  formatter.stream.write($(%formatter.result))
  formatter.stream.close()

method suiteStarted(formatter: JsonOutputFormatter, suiteName: string) =
  discard

method testStarted(formatter: JsonOutputFormatter, testName: string) =
  formatter.testErrors.setLen(0)
  formatter.testStackTrace.setLen(0)

method failureOccurred(formatter: JsonOutputFormatter,
                       checkpoints: seq[string], stackTrace: string) =
  ## ``stackTrace`` is provided only if the failure occurred due to an
  ## exception. ``checkpoints`` is never ``nil``.
  formatter.testErrors.add(checkpoints)
  if stackTrace.len > 0:
    formatter.testStackTrace = stackTrace

method testEnded(formatter: JsonOutputFormatter, testResult: TestResult) =
  var jsonTestResult: JsonTestResult
  case testResult.status
  of TestStatus.OK:
    jsonTestResult = JsonTestResult(name: testResult.testName, status: PASS)
  of TestStatus.SKIPPED:
    discard
  of TestStatus.FAILED:
    let failureMsg =
      if formatter.testStackTrace.len > 0 and formatter.testErrors.len > 0:
        formatter.testErrors[^1]
      elif formatter.testErrors.len > 0:
        formatter.testErrors[0]
      else:
        "The test failed without outputting an error"

    var errs = ""
    if formatter.testErrors.len > 1:
      let startIdx = if formatter.testStackTrace.len > 0: 0 else: 1
      let endIdx =
        if formatter.testStackTrace.len > 0:
          formatter.testErrors.len - 2
        else:
          formatter.testErrors.len - 1

      for errIdx in startIdx..endIdx:
        if errs.len > 0:
          errs.add("\n")
        errs.add(formatter.testErrors[errIdx])

    if formatter.testStackTrace.len > 0:
      jsonTestResult = JsonTestResult(
        name: testResult.testName,
        status: ERROR,
        message: fmt"{failureMsg}\n{formatter.testStackTrace}"
      )
      if errs.len > 0:
        jsonTestResult.message.insert(errs & "\n")
    else:
      jsonTestResult = JsonTestResult(
        name: testResult.testName,
        status: FAIL,
        message: fmt"{failureMsg}\n{errs}"
      )
    formatter.result = ResultJson(status: FAIL, tests: formatter.result.tests)

  formatter.result.tests.add(jsonTestResult)

method suiteEnded(formatter: JsonOutputFormatter) =
  discard
