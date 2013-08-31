{ cabal, haskellSrc, syb }:

cabal.mkDerivation (self: {
  pname = "CCA";
  version = "0.1.4";
  sha256 = "110p6529d730ydgar5ayvmji1bkf4kbz9jvadackxbf2xnfzanmj";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [ haskellSrc syb ];
  meta = {
    homepage = "not available";
    description = "preprocessor and library for Causal Commutative Arrows (CCA)";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
