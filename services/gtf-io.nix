# Defines a NixOS module which configures the website service and runs it
# shortly after the system starts up.
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.gtf.gtf-io;
in {
  # Define configuration options
  options = {
    gtf.gtf-io.enable = lib.mkOption {
      type = lib.types.bool;
      description = "Should this service run?";
      example = false;
      default = true;
    };

    gtf.gtf-io.port = lib.mkOption {
      type = lib.types.int;
      description = "The port on which the web server should run.";
      example = 8080;
      default = 8080;
    };
  };

  # Define the module configuration
  config = {
    port = cfg.port;

    # Run as a systemd service
    systemd.services.gtf-io = rec {
      # Only enable the service if it is enabled in the configuration
      inherit (cfg) enable;

      # See systemd.unit(5)
      wantedBy = ["multi-user.target"];
      after = [
        # We can't run a web server without a network interface
        "network.target"
      ];
      # Make sure systemd starts our prerequisites
      requires = after;

      # See systemd.service(5)
      serviceConfig = {
        Type = "exec";
        # Binary name comes from https://github.com/gfarrell/gtf-io
        ExecStart = "${pkgs.gtf-io}/bin/gtf-website-server ${config.port}";
      };
    };
  };
}
