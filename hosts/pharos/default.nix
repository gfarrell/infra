{
  config,
  modulesPath,
  inputs,
  lib,
  pkgs,
  ...
}: let
  website-server-port = 8080;
  draft-server-port = 8082;
  wedding-website-port = 8084;
  postgres-port = 5432;

  databases = {
    wedding = "wedding-website";
  };
in {
  networking.hostName = "pharos";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  imports = [
    "${modulesPath}/virtualisation/digital-ocean-image.nix"
    inputs.agenix.nixosModules.default

    ../../services/gtf-io.nix
    ../../services/gtf-io-drafts.nix
    ../../services/wedding-website.nix

    # Import and configure databases
    (import ./postgres.nix {
      inherit (pkgs) postgresql_16 lib;
      port = postgres-port;
      databases = lib.attrValues databases;
    })

    # Import and configure web-servers
    (import ./caddy.nix {
      inherit (pkgs) lib;
      simple_proxies = [
        {
          domain = "gtf.io";
          port = config.gtf.gtf-io.port;
          has_www = true;
        }
        {
          domain = "g-and-t.wedding";
          port = config.gtf.wedding-website.port;
          has_www = true;
        }
        {
          domain = "drafts.gtf.io";
          port = config.gtf.draft-server.port;
        }
        {
          domain = config.services.grafana.settings.server.domain;
          port = config.services.grafana.settings.server.http_port;
        }
        {
          domain = "prometheus.gtf.io";
          port = config.services.prometheus.port;
          with_custom = ''
            basicauth {
              gideon $2a$14$fxieAGKHEnHRgTDTl7AhQ.1NxAakImNUDbVasXVp0OPpDcyZsJgk2
            }
          '';
        }
      ];
    })

    # Setup monitoring using prometheus and grafana (and promtail and loki)
    (import ./prometheus.nix {inherit config;})
  ];

  virtualisation.digitalOceanImage.compressionMethod = "bzip2";

  # configure the gtf-io website module
  gtf.gtf-io = {
    enable = true;
    port = website-server-port;
  };
  gtf.draft-server = {
    enable = true;
    port = draft-server-port;
  };

  # configure the wedding website module
  gtf.wedding-website = {
    enable = true;
    port = wedding-website-port;
    db-host = "/run/postgresql";
    db-port = postgres-port;
    db-user = databases.wedding;
    db-name = databases.wedding;
  };
}
