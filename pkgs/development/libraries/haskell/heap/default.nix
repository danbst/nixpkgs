{ cabal, QuickCheck }:

cabal.mkDerivation (self: {
  pname = "heap";
  version = "1.0.0";
  sha256 = "1v1vq1lzs5h0bh85v4gqkzyg5m5mzi9bpmhph6s3xa89hi9nmp2y";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [ QuickCheck ];
  meta = {
    description = "Heaps in Haskell";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
