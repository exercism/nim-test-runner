func identity*(n: int): int =
  # Trigger a crash. See https://github.com/nim-lang/Nim/issues/11684
  for _ in []:
    discard
