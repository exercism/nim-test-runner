func hello*: string =
  debugEcho "stdout here: I have no inputs :("
  {.noSideEffect.}:
    stderr.writeLine "stderr here: no inputs :("
    stderr.flushFile
  "Hello, World!"
