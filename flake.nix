{
  description = "Infrastructure build image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
          nativeBuildInputs = with pkgs; [
            alejandra
            inputs'.agenix.packages.agenix
            nil
            morph
            curl
            just
            nix-tree
            nixos-rebuild
          ];
          shellHook = config.pre-commit.installationScript;
        };

        pre-commit.settings.hooks = {
          alejandra.enable = true;
        };

        overlayAttrs = {
          inherit (config.packages) gtf-io;
        };
      };
    };
}
