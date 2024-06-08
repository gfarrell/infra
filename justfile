# List recipes by default
default:
  just -l

# Build the NixOS configuration for a specific host
make-config HOST:
  nix build -L .#nixosConfigurations.{{HOST}}.config.system.build.toplevel

# Build the virtual imagine for provisioning the server for a given host
make-image HOST:
  nix build -L .#nixosConfigurations.{{HOST}}.config.system.build.digitalOceanImage

# Check the syntax of the flake
check-flake:
  nix flake check

# Format all files in the repo
format-all:
  pre-commit run --all-files

# Connect to a given host
connect HOST:
  ssh {{HOST}}.gtf.io

# Deploy configuration to a given host
deploy HOST:
  nixos-rebuild --fast \
                --target-host {{HOST}}.gtf.io \
                --flake .#{{HOST}} \
                --use-remote-sudo \
                switch
