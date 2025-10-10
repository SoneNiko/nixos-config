{
    description = "Default NixOs configuration flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = {self, nixpkgs, nixpkgs-stable, home-manager, ...}: {
        nixosConfigurations = {
            vm-niko-test = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./hosts/vm-niko-test/configuration.nix
                ];
            };
            desktop-niko = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./hosts/desktop-niko/configuration.nix
                ];
            };
        };

        homeConfigurations = {
            niko = home-manager.lib.homeManagerConfiguration {
                pkgs = import nixpkgs { 
                    system = "x86_64-linux"; 
                    config.allowUnfree = true;
                };
                extraSpecialArgs = { 
                    pkgs-stable = import nixpkgs-stable { 
                        system = "x86_64-linux"; 
                        config.allowUnfree = true;
                    };
                };
                modules = [
                    ./users/niko/main.nix
                ];
                backupFileExtension = "backup";
            };
        };
    };
}
