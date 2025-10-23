# git add .

# timestamp=$(date +%s)

# git commit -m "Application of config change at $timestamp"

# oco

set -euo pipefail

# Update flake inputs
nix --extra-experimental-features 'nix-command flakes' flake update

# Determine which host to apply. You can pass the short hostname (without the
# trailing "-niko") as the first argument, or the full flake key (e.g.
# "desktop-niko" / "laptop-niko"). If no arg is given we auto-detect using
# the short `hostname -s` and append "-niko".
if [ "$#" -ge 1 ] && [ -n "${1:-}" ]; then
	hostArg="$1"
	# if user passed 'desktop' or 'desktop-niko', normalize to full key
	case "$hostArg" in
		*-niko) host="$hostArg" ;;
		*) host="${hostArg}-niko" ;;
	esac
else
	short=$(hostname -s)
	host="${short}-niko"
fi

echo "Applying NixOS configuration for: $host"

# Apply the system configuration. Use sudo because this changes the system.
sudo nixos-rebuild switch --upgrade --flake .#${host}

# Apply home-manager for the `niko` user from the flake
home-manager switch --flake .#niko



