{...}: {
  imports = [./users];

  # freeze the starting NixOS state and never change it
  system.stateVersion = "23.11";

  # Clean the /tmp dir on boot
  boot.tmp.cleanOnBoot = true;

  # Save space in the nix store by hard-linking identical files.
  nix.settings.auto-optimise-store = true;

  # Set all in group wheel as trusted
  nix.settings.trusted-users = ["root" "@wheel"];

  # Enable some features of nix
  nix.extraOptions = "experimental-features = nix-command flakes";

  # Limit the systemd journal size to the lesser of 100MB or 7 days of logs
  services.journald.extraConfig = ''
    SystemMaxUse=100m
    MaxFileSec=7day
  '';
}
