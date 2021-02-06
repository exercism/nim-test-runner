import unittest
import identity

suite "Identity Function":
  test "identity function of 1":
    check identity(1) == 1
