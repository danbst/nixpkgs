{ stdenv, fetchgit, go, fetchurl }:

stdenv.mkDerivation {
  name = "nixos-shell";
  src = fetchgit {
    # Original project is unmaintained, so we're using fork with submodules fix
    #url = "https://github.com/chrisfarms/nixos-shell.git";
    url = "https://github.com/wavewave/nixos-shell.git";
    rev = "1e896190f7971e963efed6c3db45c6783dc9032b";
    sha256 = null;
    branchName = "submodule";
  };
  buildInputs = [ go ];
  phases = [ "unpackPhase" "buildPhase" ];
  buildPhase = ''
    mkdir -p $out/bin
    GOPATH=$PWD go build -o $out/bin/nixos-shell nixos-shell
  '';
}
