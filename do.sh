git add .

timestamp=$(date +%s)

git commit -m "Application of config change at $timestamp"

sudo nixos-rebuild switch --flake .#vm-niko-test

home-manager switch --flake .#niko


