func identity*(n: int): int =
  debugEcho "stdout here: my input is: " & $n
  {.noSideEffect.}:
    stderr.writeLine "stderr here: my input is: " & $n
    stderr.flushFile
  n
