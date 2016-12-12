{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.geoip-databases;

  # Use writeScriptBin instead of writeScript, so that argv[0] (logged to the
  # journal) doesn't include the long nix store path hash. (Prefixing the
  # ExecStart= command with '@' doesn't work because we start a shell (new
  # process) that creates a new argv[0].)
  updaterProg = pkgs.writeScriptBin "geoip-updater-script" ''
    #!${pkgs.stdenv.shell}
    fetchDb()
    {
        url=$1
        echo "Fetching $url ..."
        (cd ${cfg.databaseDir} && ${pkgs.curl.bin}/bin/curl --silent -LO "$url")
    }
    fetchDatabases()
    {
        base_url="https://geolite.maxmind.com/download/geoip/database"
        for db in ${lib.concatStringsSep " " cfg.databases}; do
            fetchDb "$base_url/$db"
        done
    }
    unpackDatabases()
    {
        (cd ${cfg.databaseDir} &&
            for f in *.gz; do
                test -f "$f" || continue
                ${pkgs.gzip}/bin/gzip --decompress --force -v "$f"
            done;
            for f in *.xz; do
                test -f "$f" || continue
                 ${pkgs.xz.bin}/bin/xz --decompress --force -v "$f"
            done
        )
    }
    echo "Updating GeoIP databases in ${cfg.databaseDir} ..."
    fetchDatabases
    unpackDatabases
    echo "...completed GeoIP database update in ${cfg.databaseDir}"
  '';

in

{
  options = {
    services.geoip-databases = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to enable periodic downloading of GeoIP Legacy databases from
          maxmind.com. You might want to enable this if you, for instance, use
          ntopng or Wireshark.
        '';
      };

      interval = mkOption {
        type = types.str;
        default = "weekly";
        description = ''
          Update the GeoIP databases at this time / interval.
          The format is described in
          <citerefentry><refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum></citerefentry>.
        '';
      };

      databaseDir = mkOption {
        default = "/var/lib/geoip-databases";
        description = ''
          Directory that will contain GeoIP databases.
        '';
      };

      databases = mkOption {
        default = [
          "GeoLite2-Country.mmdb.gz"
          "GeoLiteCountry/GeoIP.dat.gz"
          "GeoIPv6.dat.gz"
          "GeoLiteCity.dat.xz"
          "GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz"
          "asnum/GeoIPASNum.dat.gz"
          "asnum/GeoIPASNumv6.dat.gz"
        ];
        description = ''
          Which GeoIP databases to update.
        '';
      };

    };

  };

  config = mkIf cfg.enable {

    systemd.timers.geoip-updater =
      { description = "GeoIP Updater Service Timer";
        partOf      = [ "geoip-updater.service" ];
        wantedBy    = [ "timers.target" ];
        timerConfig.OnCalendar = cfg.interval;
        timerConfig.Persistent = "true";
      };

    systemd.services.geoip-updater = {
      description = "GeoIP Updater Service";
      after = [ "network.target" ];
      preStart = ''
        mkdir -p "${cfg.databaseDir}"
        chmod 755 "${cfg.databaseDir}"
      '';
      serviceConfig = {
        ExecStart = "${updaterProg}/bin/geoip-updater-script";
      };
    };

    systemd.services.geoip-updater-setup = {
      description = "GeoIP Updater Service Setup";
      wants = [ "geoip-updater.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
      };
    };

  };
}
