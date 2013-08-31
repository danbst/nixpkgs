{ cabal, mtl, stm }:

cabal.mkDerivation (self: {
  pname = "monadIO";
  version = "0.10.1.3";
  sha256 = "1dg0xbajd6fvygvcd4r9fsw0mq5ihcv2nm30g7dm59ijckqdp7ii";
  buildDepends = [ mtl stm ];
  meta = {
    description = "Overloading of concurrency variables";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
