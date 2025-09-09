{
    description = "Default NixOs configuration flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = {self, nixpkgs, ...}: {
        nixosConfigurations = {
            vm-niko-test = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./hosts/vm-niko-test/configuration.nix
                    home-manager.nixosModules.home-manager
                ];
            };
        };
    };
}