{ stdenv, fetchurl, makeWrapper, jre }:

stdenv.mkDerivation rec {
  version = "0.4.0-RC1";
  name = "dotty-bare-${version}";

  src = fetchurl {
    url = "https://github.com/lampepfl/dotty/releases/download/${version}/dotty-${version}.tar.gz";
    sha256 = "1d1ab08b85bd6898ce6273fa50818de0d314fc6e5377fb6ee05494827043321b";
  };

  propagatedBuildInputs = [ jre ] ;
  buildInputs = [ makeWrapper ] ;

  installPhase = ''
    mkdir -p $out
    mv * $out
  '';

  fixupPhase = ''
        bin_files=$(find $out/bin -type f ! -name common)
        for f in $bin_files ; do
          wrapProgram $f --set JAVA_HOME ${jre}
        done
  '';

  meta = with stdenv.lib; {
    description = "Research platform for new language concepts and compiler technologies for Scala.";
    longDescription = ''
       Dotty is a platform to try out new language concepts and compiler technologies for Scala.
       The focus is mainly on simplification. We remove extraneous syntax (e.g. no XML literals),
       and try to boil down Scala’s types into a smaller set of more fundamental constructs.
       The theory behind these constructs is researched in DOT, a calculus for dependent object types.
    '';
    homepage = http://dotty.epfl.ch/;
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = [maintainers.karolchmist];
  };
}
