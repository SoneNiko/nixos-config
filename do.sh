# git add .

# timestamp=$(date +%s)

# git commit -m "Application of config change at $timestamp"

oco

sudo nixos-rebuild switch --flake .#desktop-niko

home-manager switch --extra-experimental-features 'nix-command flakes' --flake .#niko


