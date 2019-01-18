let

  generic =
      # dependencies
      { stdenv, lib, fetchurl, makeWrapper
      , glibc, zlib, readline, openssl, icu, systemd, libossp_uuid
      , pkgconfig, libxml2, tzdata

      # for extensible postgreql.pkgs
      , postgresqlPackages, newScope, this

      # source specification
      , version, sha256, psqlSchema
    }:
  let
    atLeast = lib.versionAtLeast version;
    icuEnabled = atLeast "10";

  in stdenv.mkDerivation rec {
    name = "postgresql-${version}";
    inherit version;

    src = fetchurl {
      url = "mirror://postgresql/source/v${version}/${name}.tar.bz2";
      inherit sha256;
    };

    outputs = [ "out" "lib" "doc" "man" ];
    setOutputFlags = false; # $out retains configureFlags :-/

    buildInputs =
      [ zlib readline openssl libxml2 makeWrapper ]
      ++ lib.optionals icuEnabled [ icu ]
      ++ lib.optionals (atLeast "9.6" && !stdenv.isDarwin) [ systemd ]
      ++ lib.optionals (!stdenv.isDarwin) [ libossp_uuid ];

    nativeBuildInputs = lib.optionals icuEnabled [ pkgconfig ];

    enableParallelBuilding = !stdenv.isDarwin;

    makeFlags = [ "world" ];

    NIX_CFLAGS_COMPILE = [ "-I${libxml2.dev}/include/libxml2" ];

    # Otherwise it retains a reference to compiler and fails; see #44767.  TODO: better.
    preConfigure = "CC=${stdenv.cc.targetPrefix}cc";

    configureFlags = [
      "--with-openssl"
      "--with-libxml"
      "--sysconfdir=/etc"
      "--libdir=$(lib)/lib"
      "--with-system-tzdata=${tzdata}/share/zoneinfo"
      (lib.optionalString (atLeast "9.6" && !stdenv.isDarwin) "--with-systemd")
      (if stdenv.isDarwin then "--with-uuid=e2fs" else "--with-ossp-uuid")
    ] ++ lib.optionals icuEnabled [ "--with-icu" ];

    patches =
      [ (if atLeast "9.4" then ./disable-resolve_symlinks-94.patch else ./disable-resolve_symlinks.patch)
        (if atLeast "9.6" then ./less-is-more-96.patch             else ./less-is-more.patch)
        (if atLeast "9.6" then ./hardcode-pgxs-path-96.patch       else ./hardcode-pgxs-path.patch)
        ./specify_pkglibdir_at_runtime.patch
      ];

    installTargets = [ "install-world" ];

    LC_ALL = "C";

    postConfigure =
      let path = if atLeast "9.6" then "src/common/config_info.c" else "src/bin/pg_config/pg_config.c"; in
        ''
          # Hardcode the path to pgxs so pg_config returns the path in $out
          substituteInPlace "${path}" --replace HARDCODED_PGXS_PATH $out/lib
        '';

    postInstall =
      ''
        moveToOutput "lib/pgxs" "$out" # looks strange, but not deleting it
        moveToOutput "lib/*.a" "$out"
        moveToOutput "lib/libecpg*" "$out"

        # Prevent a retained dependency on gcc-wrapper.
        substituteInPlace "$out/lib/pgxs/src/Makefile.global" --replace ${stdenv.cc}/bin/ld ld

        if [ -z "''${dontDisableStatic:-}" ]; then
          # Remove static libraries in case dynamic are available.
          for i in $out/lib/*.a; do
            name="$(basename "$i")"
            ext="${stdenv.hostPlatform.extensions.sharedLibrary}"
            if [ -e "$lib/lib/''${name%.a}$ext" ] || [ -e "''${i%.a}$ext" ]; then
              rm "$i"
            fi
          done
        fi
      '';

    postFixup = lib.optionalString (!stdenv.isDarwin && stdenv.hostPlatform.libc == "glibc")
      ''
        # initdb needs access to "locale" command from glibc.
        wrapProgram $out/bin/initdb --prefix PATH ":" ${glibc.bin}/bin
      '';

    doInstallCheck = false; # needs a running daemon?

    disallowedReferences = [ stdenv.cc ];

    passthru = rec {
      inherit readline psqlSchema version;
      pkgs = lib.mapAttrs (name: value:
                if builtins.isAttrs value && builtins.hasAttr "override" value
                  then value.override { postgresql = this; }
                  else value)
                postgresqlPackages;
      callPackage = newScope (pkgs // { postgresql = this; });
      withPackages = postgresqlPackages.withPackages this (builtins.removeAttrs pkgs [
        "withPackages" "__unfix__" "extend"
      ]);
    };

    meta = with lib; {
      homepage    = https://www.postgresql.org;
      description = "A powerful, open source object-relational database system";
      license     = licenses.postgresql;
      maintainers = with maintainers; [ ocharles thoughtpolice danbst ];
      platforms   = platforms.unix;
      knownVulnerabilities = optional (!atLeast "9.4")
        "PostgreSQL versions older than 9.4 are not maintained anymore!";
    };
  };

in self: super: {

  postgresqlPackages = self.lib.makeExtensible (self_:
    let this = self.lib.fixedPoints.mergeUpdate self self.postgresqlPackages // {
      callPackage = self.newScope this;
    };
  in {
    withPackages = postgresql: pkgs: f: self.buildEnv {
      name = "postgresql-and-plugins-${postgresql.version}";
      paths = f pkgs ++ [
          postgresql
          postgresql.lib
          postgresql.man   # in case user installs this into environment
      ];
      buildInputs = [ self.makeWrapper ];

      # We include /bin to ensure the $out/bin directory is created, which is
      # needed because we'll be removing the files from that directory in postBuild
      # below. See #22653
      pathsToLink = ["/" "/bin"];

      postBuild = ''
        mkdir -p $out/bin
        rm $out/bin/{pg_config,postgres,pg_ctl}
        cp --target-directory=$out/bin ${postgresql}/bin/{postgres,pg_config,pg_ctl}
        wrapProgram $out/bin/postgres --set NIX_PGLIBDIR $out/lib
      '';
    };

    pg_repack = this.callPackage ./pg_repack { };

    pg_similarity = this.callPackage ./pg_similarity { };

    pgroonga = self.callPackage ./pgroonga { };

    plv8 = this.callPackage ./plv8 {
      v8 = this.callPackage ../../../development/libraries/v8/plv8_6_x.nix {
        python = this.python2;
      };
    };

    jdbc = this.callPackage ./pgjwt { };

    pgjwt = this.callPackage ./pgjwt { };

    cstore_fdw = this.callPackage ./cstore_fdw { };

    pg_hll = this.callPackage ./pg_hll { };

    pg_cron = this.callPackage ./pg_cron { };

    pg_topn = this.callPackage ./topn { };

    pgtap = this.callPackage ./pgtap { };

    psqlodbc = this.callPackage ./psqlodbc { };

    timescaledb = this.callPackage ./timescaledb { };

    tsearch_extras = this.callPackage ./tsearch_extras { };
  });

  postgresql = self.postgresql_9_6;

  postgresql_9_4 = self.callPackage generic {
    version = "9.4.20";
    psqlSchema = "9.4";
    sha256 = "0zzqjz5jrn624hzh04drpj6axh30a9k6bgawid6rwk45nbfxicgf";
    this = self.postgresql_9_4;
  };

  postgresql_9_5 = self.callPackage generic {
    version = "9.5.15";
    psqlSchema = "9.5";
    sha256 = "0i2lylgmsmy2g1ixlvl112fryp7jmrd0i2brk8sxb7vzzpg3znnv";
    this = self.postgresql_9_5;
  };

  postgresql_9_6 = self.callPackage generic {
    version = "9.6.11";
    psqlSchema = "9.6";
    sha256 = "0c55akrkzqd6p6a8hr0338wk246hl76r9j16p4zn3s51d7f0l99q";
    this = self.postgresql_9_6;
  };

  postgresql_10 = self.callPackage generic {
    version = "10.6";
    psqlSchema = "10.0";
    sha256 = "0jv26y3f10svrjxzsgqxg956c86b664azyk2wppzpa5x11pjga38";
    this = self.postgresql_10;
  };

  postgresql_11 = self.callPackage generic {
    version = "11.1";
    psqlSchema = "11.1";
    sha256 = "026v0sicsh7avzi45waf8shcbhivyxmi7qgn9fd1x0vl520mx0ch";
    this = self.postgresql_11;
  };

}