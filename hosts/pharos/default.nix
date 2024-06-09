{modulesPath, ...}: let
  website-server-port = 8080;
in {
  imports = [
    "${modulesPath}/virtualisation/digital-ocean-image.nix"
    ../../services/gtf-io.nix
  ];

  virtualisation.digitalOceanImage.compressionMethod = "bzip2";

  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        metrics
      }
    '';
    virtualHosts."gtf.io".extraConfig = ''
      redir http://www.{host}{uri}
    '';
    virtualHosts."www.gtf.io".extraConfig = ''
      encode gzip
      reverse_proxy localhost:${toString website-server-port}
    '';
    virtualHosts."prometheus.gtf.io".extraConfig = ''
      basicauth {
        gideon $2a$14$fxieAGKHEnHRgTDTl7AhQ.1NxAakImNUDbVasXVp0OPpDcyZsJgk2
      }
      encode gzip
      reverse_proxy localhost:9090
    '';
  };

  # configure the gtf-io website module
  gtf.gtf-io = {
    enable = true;
    port = website-server-port;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  # Export data to prometheus
  # https://wiki.nixos.org/wiki/Prometheus
  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    enabledCollectors = ["systemd"];
    listenAddress = "localhost";
  };
  # And run a local prometheus server
  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:9000" # pharos system metrics
              "localhost:2019" # caddy exports its own metrics here
            ];
          }
        ];
      }
    ];
  };

  networking.hostName = "pharos";
}
