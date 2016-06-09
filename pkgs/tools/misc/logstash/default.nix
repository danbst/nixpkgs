{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "2.3.2";
  name = "logstash-${version}";

  src = fetchurl {
    url = "https://download.elasticsearch.org/logstash/logstash/logstash-${version}.tar.gz";
    sha256 = "1h9qvm48vx938ymscw5qp9cmk76z15lfydk7723q0g17z91xkjdk";
  };

  dontBuild         = true;
  dontPatchELF      = true;
  dontStrip         = true;
  dontPatchShebangs = true;

  installPhase = ''
    mkdir -p $out
    cp -r {Gemfile*,vendor,lib,bin} $out
    rm $out/bin/plugin
    chmod -x $out/bin/logstash.lib.sh
  '';

  meta = with stdenv.lib; {
    description = "Logstash is a data pipeline that helps you process logs and other event data from a variety of systems";
    homepage    = https://www.elastic.co/products/logstash;
    license     = licenses.asl20;
    platforms   = platforms.unix;
    maintainers = [ maintainers.wjlroe maintainers.offline ];
  };
}
