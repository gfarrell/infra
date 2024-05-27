{
  description = "Infrastructure build image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    agenix.url = "github:ryantm/agenix";

    gtf-io = {
      url = "github:gfarrell/gtf.io/trunk";
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
      ];

      flake = {
        config,
        pkgs,
        ...
      }: let
        commonModules = [./common];

        mkSystem = system: extraModules:
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = commonModules ++ extraModules;
            specialArgs = {
              inherit inputs;
              inherit system;
            };
          };
      in {
        nixosConfigurations = {
          pharos = mkSystem "x86_64-linux" [./hosts/pharos];
        };
      };

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        agenix,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [alejandra nil];
          shellHook = config.pre-commit.installationScript;
        };

        pre-commit.settings.hooks = {
          alejandra.enable = true;
          shellcheck.enable = true;
        };
      };
    };
}
