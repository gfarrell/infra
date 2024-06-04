{modulesPath, ...}: let
  website-server-port = 8080;
in {
  imports = [
    "${modulesPath}/virtualisation/digital-ocean-image.nix"
    # inputs.self.nixosModules.gtf-io
    ../../services/gtf-io.nix
  ];

  services.caddy = {
    enable = true;
    virtualHosts."gtf.io".extraConfig = ''
      encode gzip
      reverse_proxy localhost:${toString website-server-port}
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

  networking.hostName = "pharos";
}
