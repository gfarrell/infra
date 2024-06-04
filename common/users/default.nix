{pkgs, ...}: let
  keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqMATgxH6E58IIRVGsteE9xvlYWT+HkHL16F+c0It6mKpjcvKQS89Z8L8mFVAfzYvSwNrjiFiTkmf3+OMww8ZaGp+5Ld5FyvFhybBT4LkErx1glNVftTrbTMdYJ2Jwru5Ou1SiGQC8izrRGqAfqEnpaArjLL31GwkQT+QRdZSdUKNAap1aYio8T6bK2iZ4O8bRl7N8AOog419rwpLsLeyOWo4SRO5cf6L893uV290lZedPICleZn9lqWFLBKqbu04DawlKQcZchNnom5WKu1UmzRz4K++59wHvz7DQpkOuJZWSEFp57ukpOigi+ESEuAORDowTzVKbp9VT5KNGjrYaQ== gideon@anaximander.gtf.io"
  ];
in {
  users.users.gideon = {
    isNormalUser = true;
    home = "/home/gideon";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = keys;
    packages = with pkgs; [htop ripgrep neovim tmux zsh];
  };

  services.openssh = {
    enable = true;
    ports = [2712];
    settings.PermitRootLogin = "no";
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
}
