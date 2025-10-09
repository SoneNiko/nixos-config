{
    description = "Default NixOs configuration flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        android-nixpkgs = {
            url = "github:tadfisher/android-nixpkgs/stable";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = {self, nixpkgs, home-manager, android-nixpkgs, ...}: {
        nixosConfigurations = {
            vm-niko-test = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit android-nixpkgs; };
                modules = [
                    ./hosts/vm-niko-test/configuration.nix
                ];
            };
            desktop-niko = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit android-nixpkgs; };
                modules = [
                    ./hosts/desktop-niko/configuration.nix
                ];
            };
        };

        homeConfigurations = {
            niko = home-manager.lib.homeManagerConfiguration {
                pkgs = import nixpkgs { system = "x86_64-linux"; };
                extraSpecialArgs = { inherit android-nixpkgs; };
                modules = [
                    ./users/niko/main.nix
                ];
            };
        };
    };
}
