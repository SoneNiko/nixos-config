# hosts/laptop-niko/configuration.nix
{ config, pkgs, pkgsStable, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;
    # Prevent Nix from attempting to change EFI variables / run `bootctl`.
    # On some systems the firmware or another boot loader owns the ESP entries
    # and `bootctl update` can fail with a non-zero exit status during
    # `nixos-rebuild`. Setting `canTouchEfiVariables = false` will avoid
    # modifying EFI variables while still allowing the NixOS configuration
    # to use systemd-boot (you keep the current bootloader entries).
    boot.loader.efi.canTouchEfiVariables = false;
    # Bootloader: manage systemd-boot for the laptop. Disable GRUB here to avoid
    # conflicts with firmware preferring systemd-boot.

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable KVM virtualization
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    # Enable nested virtualization for better Android emulator performance
    kvmgt.enable = true;
    docker.enable = true;
  };

  # Enable flakes and other experimental features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  networking.hostName = "LAPTOP-NIKO"; # Define your hostname.

  # Enable networking
  networking.networkmanager = {
    enable = true;
    # Enable VPN plugins for NetworkManager (OpenVPN support)
    plugins = with pkgs; [ networkmanager-openvpn ];
  };

  # Fix for eduVPN / WireGuard - disable strict reverse path filtering
  # This allows WireGuard VPN connections to work properly
  networking.firewall.checkReversePath = "loose";

  # Enable OpenVPN for eduVPN TCP fallback
  # OpenVPN should work out of the box according to docs, but ensure it's not blocked
  services.openvpn.servers = { };

  # Set your time zone.
  time.timeZone = "Europe/Luxembourg";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account.
  users.users.niko = {
    isNormalUser = true;
    description = "Nikolas Heise";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "kvm" "docker" ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages and accept Android SDK license
  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    vscode
    texliveFull
    htop
    tree
    direnv
    home-manager
    gh
    tldr spotify
    discord-canary mesa-demos libva-utils glmark2 vivaldi vivaldi-ffmpeg-codecs
    opencommit freecad localsend lsd bat ripgrep ripgrep-all fzf
    protonup-qt protontricks wine winetricks signal-desktop qemu libvirt
    dxvk vkd3d-proton pferd mattermost-desktop zotero html2pdf libreoffice-qt6-fresh mpv
    yt-dlp eduvpn-client openvpn3 ntfs3g
    python314 libnotify kdePackages.plasma-browser-integration quarkus
    nodejs yarn vite openjdk21 quarkus obsidian
  ];

  # Enable Android development environment
  programs.adb.enable = true;
  
  # Enable hardware acceleration for Android emulator and 32-bit games/Wine/Proton
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Ensure 32-bit DRI support for 32-bit games and Wine/Proton
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  # Enable Bluetooth hardware support
  hardware.bluetooth = {
    enable = true;
    # powerOnBoot = true;
    # settings = {
    #   General = {
    #     # Shows battery charge of connected devices on supported
    #     # Bluetooth adapters. Defaults to 'false'.
    #     Experimental = true;
    #     # When enabled other devices can connect faster to us, however
    #     # the tradeoff is increased power consumption. Defaults to
    #     # 'false'.
    #     FastConnectable = true;
    #   };
    #   Policy = {
    #     # Enable all controllers when they are found. This includes
    #     # adapters present on start as well as adapters that are plugged
    #     # in later on. Defaults to 'true'.
    #     AutoEnable = true;
    #   };
    # };
  };


  programs.nix-ld.enable = true;

  # Font configuration
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
    fontconfig = {
      defaultFonts = { monospace = [ "JetBrainsMono Nerd Font" ]; };
    };
  };

  services.tailscale.enable = true;

  xdg.mime.defaultApplications = {
    "text/html" = "vivaldi.desktop";
    "x-scheme-handler/http" = "vivaldi.desktop";
    "x-scheme-handler/https" = "vivaldi.desktop";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.pcscd.enable = true;

  # This value determines the NixOS release for stateful defaults
  system.stateVersion = "25.05";

  # ---- Home Manager as a NixOS module ----

  # Make Home Manager create backups (append `.backup`) instead of aborting on conflicts
  home-manager.backupFileExtension = "backup";

  # Provide the home-manager user module (import the user-specific home config)
  # Path is relative to this file: hosts/desktop-niko -> users/niko/main.nix
  # Register the module fragment so the NixOS/home-manager module system
  # supplies the usual `config`, `pkgs`, `lib`, etc. arguments.
  home-manager.users.niko = {
    imports = [ ../../users/niko/main.nix ];
  };

  # Disable systemd-boot-random-seed.service to prevent bootctl invocation.
  systemd.services."systemd-boot-random-seed".enable = false;

  hardware.fw-fanctrl.enable = true;

}
