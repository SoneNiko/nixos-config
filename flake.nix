# flake.nix
{
  description = "NixOS + Home Manager flake (desktop-niko + vm-niko-test) with Home Manager enabled as a NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      hm = home-manager;
      pkgsStable = import nixpkgs-stable { inherit system; };
    in {
      nixosConfigurations = {
        desktop-niko = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/desktop-niko/configuration.nix
            hm.nixosModules.home-manager
          ];
          # make pkgs-stable available to home modules that reference it
          specialArgs = { inherit hm pkgsStable; };
        };
        laptop-niko = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/laptop-niko/configuration.nix
            hm.nixosModules.home-manager
          ];
          # make pkgs-stable available to home modules that reference it
          specialArgs = { inherit hm pkgsStable; };
        };
      };

      # Provide a flake-level homeConfiguration so `home-manager --flake .#niko`
      # and `home-manager switch --flake .#niko` can find an activationPackage.
      homeConfigurations = {
        niko = hm.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [ ./users/niko/main.nix ];
        };
      };

      devShells = {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs
            pkgs.yarn
            pkgs.vite
          ];
        };
        holoheise = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs
            pkgs.yarn
            pkgs.vite
            pkgs.openjdk21
            pkgs.quarkus
          ];
        };
      };
    };
}
