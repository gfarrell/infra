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

      db-name = lib.mkOption {
        type = lib.types.str;
        description = "The name of the PostgreSQL database for this service.";
        example = "wedding-website";
        default = "wedding-website";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure agenix secrets
    age.secrets.wedding-website-db-password = {
      file = ../secrets/wedding-website-db-password.age;
      mode = "400";
      owner = "wedding-website";
    };

    age.secrets.wedding-website-rsvp-password = {
      file = ../secrets/wedding-website-rsvp-password.age;
      mode = "400";
      owner = "wedding-website";
    };

    # Create dedicated system user and group
    users.users.wedding-website = {
      isSystemUser = true;
      group = "wedding-website";
    };

    users.groups.wedding-website = {};

    systemd.services.wedding-website = {
      wantedBy = ["multi-user.target"];
      after = [
        "network.target"
        "postgresql.service"
      ];
      requires = [
        "network.target"
        "postgresql.service"
      ];

      serviceConfig = {
        Type = "exec";
        User = "wedding-website";
        Group = "wedding-website";
        ExecStart = ''
          ${pkgs.wedding-website}/bin/wedding-website \
            --production \
            --port ${toString cfg.port} \
            --db-host "${cfg.db-host}" \
            --db-port ${toString cfg.db-port} \
            --db-name "${cfg.db-name}" \
            --db-user "${cfg.db-user}" \
            --db-password-path "${config.age.secrets.wedding-website-db-password.path}" \
            --rsvp-password-path "${config.age.secrets.wedding-website-rsvp-password.path}"
        '';
      };
    };
  };
}
