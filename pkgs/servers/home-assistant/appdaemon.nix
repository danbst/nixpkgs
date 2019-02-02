{ lib, python3 }:

let
  overrides = self: super: {
    aiohttp = { src, ... }: src // {
      version = "2.3.10";
      sha256 = "8adda6583ba438a4c70693374e10b60168663ffa6564c5c75d3c7a9055290964";
    };
    yarl = { src, ... }: src // {
      version = "1.1.0";
      sha256 = "6af895b45bd49254cc309ac0fe6e1595636a024953d710e01114257736184698";
    };
    aihttp-jinja2 = { src, ... }: src // {
      version = "0.15.0";
      sha256 = "0f390693f46173d8ffb95669acbb0e2a3ec54ecce676703510ad47f1a6d9dc83";
    };
  };

  genericOverride = p: ov: if isFunction ov then p.overrideAttrs (sup: ov sup) else p.overrideAttrs (sup: ov);

  x = python3.newPython {
    packageOverrides = self: super: let ove = overrides self super; in
      lib.mapAttrs (n: v:
        genericOverride v (ove.${n}))
      (builtins.intersectAttrs overrides super);
    this = x;
  };
  python = (python3 // {
    pkgs = python3.pkgs // (let super = python3.pkgs; in {
      aiohttp = super.aiohttp.overridePythonAttrs (oldAttrs: rec {
        version = "2.3.10";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "8adda6583ba438a4c70693374e10b60168663ffa6564c5c75d3c7a9055290964";
        };
        # TODO: remove after pinning aiohttp to a newer version
        propagatedBuildInputs = with self; [ chardet multidict async-timeout yarl idna-ssl ];
        doCheck = false;
      });

      yarl = super.yarl.overridePythonAttrs (oldAttrs: rec {
        version = "1.1.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "6af895b45bd49254cc309ac0fe6e1595636a024953d710e01114257736184698";
        };
      });

      aiohttp-jinja2 = super.aiohttp-jinja2.overridePythonAttrs (oldAttrs: rec {
        version = "0.15.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "0f390693f46173d8ffb95669acbb0e2a3ec54ecce676703510ad47f1a6d9dc83";
        };
      });
    });
  }).override { inherit python; };

  python = python3.override {
    packageOverrides = self: super: {

      aiohttp = super.aiohttp.overridePythonAttrs (oldAttrs: rec {
        version = "2.3.10";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "8adda6583ba438a4c70693374e10b60168663ffa6564c5c75d3c7a9055290964";
        };
        # TODO: remove after pinning aiohttp to a newer version
        propagatedBuildInputs = with self; [ chardet multidict async-timeout yarl idna-ssl ];
        doCheck = false;
      });

      yarl = super.yarl.overridePythonAttrs (oldAttrs: rec {
        version = "1.1.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "6af895b45bd49254cc309ac0fe6e1595636a024953d710e01114257736184698";
        };
      });

      aiohttp-jinja2 = super.aiohttp-jinja2.overridePythonAttrs (oldAttrs: rec {
        version = "0.15.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "0f390693f46173d8ffb95669acbb0e2a3ec54ecce676703510ad47f1a6d9dc83";
        };
      });

    };
  };

in python.pkgs.buildPythonApplication rec {
  pname = "appdaemon";
  version = "3.0.2";

  src = python.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "c32d9139566cc8147c39196a18c317accd1f0b2ef8e6c0ff31bddd4bc0f80bd3";
  };

  propagatedBuildInputs = with python.pkgs; [
    daemonize astral requests sseclient websocket_client aiohttp yarl jinja2
    aiohttp-jinja2 pyyaml voluptuous feedparser iso8601 bcrypt paho-mqtt
  ];

  # no tests implemented
  doCheck = false;

  meta = with lib; {
    description = "Sandboxed python execution environment for writing automation apps for Home Assistant";
    homepage = https://github.com/home-assistant/appdaemon;
    license = licenses.mit;
    maintainers = with maintainers; [ peterhoeg dotlambda ];
  };
}
