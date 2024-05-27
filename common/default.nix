{...}: {
  imports = [./users];

  system.stateVersion = "23.11";

  # Clean the /tmp dir on boot
  boot.tmp.cleanOnBoot = true;

  # Save space in the nix store by hard-linking identical files.
  nix.settings.auto-optimise-store = true;

  # Limit the systemd journal size to the lesser of 100MB or 7 days of logs
  services.journald.extraConfig = ''
    SystemMaxUse=100m
    MaxFileSec=7day
  '';

  # Use systemd-resolved for DNS, but without dnssec because (apparently) it's
  # broken (TODO: must as LD about this)
  services.resolved = {
    enable = true;
    dnssec = "false";
  };
}
