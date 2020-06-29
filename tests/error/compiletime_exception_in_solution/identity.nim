func identity*(n: int): int =
  static:
    raise newException(ValueError, "myValueError")
