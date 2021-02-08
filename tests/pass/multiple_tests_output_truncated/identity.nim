import strutils

const longString = "_123456789".repeat(50)
doAssert longString.len == 500

proc identity*(n: int): int =
  if n == 1:
    echo longString[0 .. ^3] # len of 499, including '\n' from `echo`
  elif n == 2:
    echo longString[0 .. ^2] # len of 500, including '\n' from `echo`
  elif n == 3:
    echo longString          # len of 501, including '\n' from `echo`

  result = n
