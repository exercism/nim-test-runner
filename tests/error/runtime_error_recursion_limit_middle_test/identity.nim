func identity*(n: int): int =
  if n == 2:
    identity(n)
  else:
    n
