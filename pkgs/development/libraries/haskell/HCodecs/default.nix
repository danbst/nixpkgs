{ cabal, QuickCheck, random }:

cabal.mkDerivation (self: {
  pname = "HCodecs";
  version = "0.2.2";
  sha256 = "049jj8h46l0i08nimbyf6bqgmwb86axjzh4zbma2kzhcsqfyg519";
  buildDepends = [ QuickCheck random ];
  meta = {
    homepage = "http://www-db.informatik.uni-tuebingen.de/team/giorgidze";
    description = "A library to read, write and manipulate MIDI, WAVE, and SoundFont2 files";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
