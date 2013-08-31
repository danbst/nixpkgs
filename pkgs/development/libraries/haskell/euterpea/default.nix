{ fetchurl, cabal, deepseq, GLFW, haskellSrcExts
, mtl, OpenGL, random, stm, syb
, HCodecs, heap, markov-chain, monadIO, pure-fft, CCA, PortMidi
}:

cabal.mkDerivation (self: {
  pname = "Euterpea";
  version = "1.0.0";
  sha256 = "1gnvw20fm70fv7c9bzspqfhy9n22ll9yigs1hfxrwavkqzlwflb6";
  buildDepends = [
    deepseq GLFW haskellSrcExts HCodecs heap markov-chain monadIO
    mtl OpenGL PortMidi pure-fft random stm syb CCA
  ];
  src = fetchurl {
    url = "https://github.com/dwincort/Euterpea/archive/master.zip";
    sha256 = "1gnvw20fm70fv7c9bzspqfhy9n22ll9yigs1hfxrwavkqzlwflb6";
  };
  meta = {
    homepage = "http://haskell.cs.yale.edu/";
    description = "Library for computer music research and education";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
