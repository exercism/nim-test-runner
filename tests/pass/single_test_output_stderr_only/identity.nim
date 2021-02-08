proc identity*(n: int): int =
  stderr.writeLine "stderr here: my input is: " & $n
  stderr.flushFile
  result = n
