{ cabal, asound }:

cabal.mkDerivation (self: {
  pname = "PortMidi";
  version = "0.1.3";
  sha256 = "1sjs73jpdsb610l6b8i7pr019ijddz7zqv56f4yy843ix848yqzp";
  extraLibraries = [ asound ];
  meta = {
    homepage = "http://haskell.org/haskellwiki/PortMidi";
    description = "A binding for PortMedia/PortMidi";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
