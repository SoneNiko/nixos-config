{
    description = "Default NixOs configuration flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    outputs = {self, nixpkgs, ...}: {
        nixosConfigurations = {
            vm-niko-test = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./hosts/vm-niko-test/configuration.nix
                ];
            };
        };
    };
}