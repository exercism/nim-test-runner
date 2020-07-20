import unittest
import identity

suite "Identity Function":
  test "identity function of 1":
    check identity(1) == 1

  test "identity function of 2":
    check identity(2) == 2

  test "identity function of 3":
    check identity(3) == 3
