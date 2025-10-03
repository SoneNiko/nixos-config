# git add .

# timestamp=$(date +%s)

# git commit -m "Application of config change at $timestamp"

nix --extra-experimental-features 'nix-command flakes' flake update

sudo nixos-rebuild switch --upgrade --flake .#desktop-niko

home-manager switch --upgrade --extra-experimental-features 'nix-command flakes' --flake .#niko

oco


