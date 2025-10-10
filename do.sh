# git add .

# timestamp=$(date +%s)

# git commit -m "Application of config change at $timestamp"

oco

nix flake update

sudo nixos-rebuild switch --upgrade --flake .#desktop-niko

home-manager switch --flake .#niko



