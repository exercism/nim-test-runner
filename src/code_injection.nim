import macros

macro injectCode*(fileName: string, codeToInject): untyped =
  result = codeToInject
  result.add parseStmt fileName.strVal.staticRead
