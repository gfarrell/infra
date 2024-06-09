{
  description = "Infrastructure build image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    gtf-io = {
      url = "github:gfarrell/gtf.io/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        inputs.pre-commit-hooks.flakeModule

        # Allow perSystem to add entries to the default overlay
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      flake = {
        config,
        pkgs,
        ...
      }: let
        mkHost = system: extraModules:
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              inherit inputs;
            };

            modules = [./common] ++ extraModules;
          };
      in {
        nixosConfigurations = {
          pharos = let
            system = "x86_64-linux";
          in
            mkHost system [
              # enable some custom packages from inputs
              {
                nixpkgs.overlays = [
                  (final: prev: {
                    gtf-io = inputs.gtf-io.packages.${system}.default;
                  })
                ];
              }
              # load machine-specific configuration
              ./hosts/pharos
            ];
        };
      };

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [alejandra nil morph curl just nixos-rebuild];
          shellHook = config.pre-commit.installationScript;
        };

        pre-commit.settings.hooks = {
          alejandra.enable = true;
          shellcheck.enable = true;
        };

        overlayAttrs = {
          inherit (config.packages) gtf-io;
        };
      };
    };
}
