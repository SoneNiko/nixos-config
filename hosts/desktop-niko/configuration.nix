# hosts/desktop-niko/configuration.nix
{ config, pkgs, pkgsStable, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable KVM virtualization
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    # Enable nested virtualization for better Android emulator performance
    kvmgt.enable = true;
  };

  # Enable flakes and other experimental features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  networking.hostName = "DESKTOP-NIKO"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

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
    extraGroups = [ "networkmanager" "wheel" "adbusers" "kvm" ];
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
    git vim wget vscode jetbrains-toolbox texliveFull htop tree direnv home-manager gh tldr spotify
    discord-canary mesa-demos libva-utils glmark2 protonup-qt vivaldi vivaldi-ffmpeg-codecs easyeffects
    steam-tui steamcmd opencommit heroic freecad localsend lsd bat ripgrep ripgrep-all fzf
    nexusmods-app-unfree protontricks wine winetricks signal-desktop qemu libvirt
    dxvk vkd3d-proton vulkan-tools zotero pferd mattermost-desktop html2pdf libreoffice-qt6-fresh mpv
    yt-dlp
    python314 libnotify eduvpn-client
  ];

  # Enable Android development environment
  programs.adb.enable = true;
  
  # Enable hardware acceleration for Android emulator and 32-bit games/Wine/Proton
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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
}
