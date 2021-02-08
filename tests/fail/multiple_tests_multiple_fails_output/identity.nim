proc identity*(n: int): int =
  echo "stdout here: my input is: " & $n
  stderr.writeLine "stderr here: my input is: " & $n
  stderr.flushFile
  result = n
