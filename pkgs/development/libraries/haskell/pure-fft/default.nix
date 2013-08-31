{ cabal }:

cabal.mkDerivation (self: {
  pname = "pure-fft";
  version = "0.2.0";
  sha256 = "1zzravfgxbx07c38pf0p73a9nzjk2pbq3hzfw8v9zkqj95b3l94i";
  meta = {
    description = "Fast Fourier Transform";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
