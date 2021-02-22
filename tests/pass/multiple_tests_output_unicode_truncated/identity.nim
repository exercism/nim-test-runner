import std/[strutils, unicode]

const
  longString = "_➊➋➌➍➎➏➐➑➒".repeat(50)
  manyRunes = toRunes(longString)
  maxRuneLen = 500

doAssert manyRunes.len == maxRuneLen

proc identity*(n: int): int =
  if n == 1:
    echo manyRunes[0 .. ^3] # runeLen of 499, including '\n' from `echo`
  elif n == 2:
    echo manyRunes[0 .. ^2] # runeLen of 500, including '\n' from `echo`
  elif n == 3:
    echo manyRunes          # runeLen of 501, including '\n' from `echo`

  result = n
