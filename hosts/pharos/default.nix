{
  modulesPath,
  inputs,
  system,
  ...
}: let
  website-server-port = "2712";
in {
  imports = ["${modulesPath}/virtualisation/digital-ocean-image.nix"];

  services.caddy = {
    enable = true;
    virtualHosts."gtf.io".extraConfig = ''
      encode gzip
      reverse_proxy localhost:${website-server-port}
    '';
  };

  systemd.services.gtf-io = {
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "@${inputs.gtf-io.packages."${system}".default} ${website-server-port}";
      Restart = "always";
      User = "webrunner";
    };
  };

  # This user is specific to this host
  users.users.webrunner = {
    isSystemUser = true;
    group = "webrunner";
  };
  users.groups.webrunner = {};

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  networking.hostName = "pharos";
}
