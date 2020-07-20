func hello*: string =
  {.noSideEffect.}:
    stderr.writeLine "煐鍆࠭会띈펍⡡壺෬埯ಂޘ๣俫ࢀ역嘥⟺꧁⏶紤刏益ꮶ炬忤륻ᵤ࿖℉䤦쐽罤撦揳ﾥꡌ"
    stderr.flushFile
  "Hello, World!"
