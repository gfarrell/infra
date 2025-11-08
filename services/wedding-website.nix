{
  config,
  pkgs,
  lib,
  ...
}: let
    cfg = config.gtf.wedding-website;
in {
  options = {
    gtf.wedding-website = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Should this service run?";
        example = false;
        default = true;
      };

      port = lib.mkOption {
        type = lib.types.int;
        description = "The port on which the web server should run.";
        example = 8080;
        default = 8081;
      };

      db-host = lib.mkOption {
        type = lib.types.str;
        description = "The PostgreSQL host.";
        example = "localhost";
        default = "localhost";
      };

      db-port = lib.mkOption {
        type = lib.types.port;
        description = "The PostgreSQL port.";
        example = 5432;
        default = 5432;
      };

      db-user = lib.mkOption {
        type = lib.types.str;
        description = "The PostgreSQL user for this service.";
        example = "wedding-website";
        default = "wedding-website";
      };

      db-password = lib.mkOption {
        type = lib.types.str;
        description = "The password for the PostgreSQL user.";
      };

      db-name = lib.mkOption {
        type = lib.types.str;
        description = "The name of the PostgreSQL database for this service.";
        example = "wedding-website";
        default = "wedding-website";
      };

      rsvp-password = lib.mkOption {
        type = lib.types.str;
        description = "The password for the RSVP pages.";
      };
    };
  };

  config = {
    systemd.services.wedding-website = rec {
      inherit (cfg) enable;

      wantedBy = ["multi-user.target"];
      after = [
        "network.target"
        "postgresql.service"
      ];
      requires = after;

      serviceConfig = {
        Type = "exec";
        ExecStart = ''
          ${pkgs.wedding-website}/bin/wedding-website \
            --production \
            --port ${toString cfg.port} \
            --db-host "${cfg.db-host}" \
            --db-port ${toString cfg.db-port} \
            --db-name "${cfg.db-name}" \
            --db-user "${cfg.db-user}" \
            --db-password "${cfg.db-password}" \
            --rsvp-password "${cfg.rsvp-password}"
        '';
      };
    };
  };
}
