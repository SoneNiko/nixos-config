# users/niko/main.nix
{ pkgs, lib, ... }:
{
  # Allow unfree packages for Android SDK
  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  home.username = "niko";
  home.homeDirectory = "/home/niko";

  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
    BROWSER = "vivaldi";
    TERMINAL = "ghostty";
    JAVA_HOME = "/home/niko/.jdks/corretto-24.0.2/";
    ANDROID_HOME = "/home/niko/.android-sdk";
    ANDROID_SDK_ROOT = "/home/niko/.android-sdk";
    PATH = "/home/niko/.android-sdk/platform-tools:/home/niko/.android-sdk/tools:/home/niko/.android-sdk/tools/bin:$PATH";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    shellAliases = { ls = "lsd"; la = "lsd -la"; l = "lsd -l"; };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "Nikolas Heise";
        email = "nikolasheise683@gmail.com";
        signingkey = "891AFE673465C446";
      };
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      commit.gpgsign = true;
    };
  };

  programs.ghostty = {
    settings = { theme = "Dark Modern"; };
    enableBashIntegration = true;
    installBatSyntax = true;
    enable = true;
  };

  # https://github.com/abraunegg/onedrive/blob/master/config are the valid options
  programs.onedrive = {
    enable = true;
    settings = {
      display_running_config = "true";
      display_transfer_metrics = "true";
      enable_logging = "true";
      log_dir = "/var/log/onedrive/";
      recycle_bin_path = "/home/niko/.local/share/Trash/files/";
      sync_dir_permissions = "700";
      sync_file_permissions = "700";
      threads = "14";
    };
  };

  programs.oh-my-posh = {
    enable = true;
    enableBashIntegration = true;
    useTheme = "slimfat";
  };

  programs.vivaldi = {
    nativeMessagingHosts = [
      pkgs.kdePackages.plasma-browser-integration
    ];
  };

  home.packages = with pkgs; [
    # Android development - Complete setup for API 36
    android-studio

    # Android SDK with all necessary components for API 36
    (androidenv.composeAndroidPackages {
      cmdLineToolsVersion = "11.0";
      buildToolsVersions = [ "34.0.0" "35.0.0" "36.0.0" ];
      platformVersions = [ "34" "35" "36" ];
      abiVersions = [ "x86_64" "arm64-v8a" "armeabi-v7a" ];
      systemImageTypes = [ "google_apis_playstore" "google_apis" "default" ];
      includeEmulator = true;
      includeSystemImages = true;
      includeNDK = true;
      includeCmake = true;
      includeExtras = [
        "extras;google;auto"
        "extras;google;google_play_services"
        "extras;android;m2repository"
        "extras;google;m2repository"
      ];
      extraLicenses = [
        "android-googletv-license"
        "android-sdk-preview-license"
        "google-gdk-license"
        "mips-android-sysimage-license"
      ];
    }).androidsdk

    # Additional useful tools for Android development
    scrcpy  # Screen mirroring for Android devices
    gradle  # Build tool (though Android Studio includes this)
  ] ++ [
    # JetBrains IDEs (from the same pkgs set); if you specifically need
    # stable nixpkgs packages, consider pulling them directly in the
    # flake inputs and referencing them explicitly.
    pkgs.jetbrains.idea-ultimate
    pkgs.jetbrains.rider
    pkgs.jetbrains.pycharm-professional
    pkgs.jetbrains.rust-rover
  ];

  home.activation.androidSdk = ''
    mkdir -p /home/niko
    if [ ! -L /home/niko/.android-sdk ]; then
      ln -sf /home/niko/.nix-profile/libexec/android-sdk /home/niko/.android-sdk
    fi
  '';

  # Install systemd user unit files for the OneDrive sanitizer and provide a
  # session command to enable the timer when the user session starts.
  home.file."/home/niko/.config/systemd/user/sanitize-onedrive.service".text = ''
[Unit]
Description=Sanitize OneDrive filenames and notify

[Service]
Type=oneshot
ExecStart=${pkgs.python314}/bin/python3 /home/niko/nixos-config/scripts/sanitize_onedrive.py --yes
'';

  home.file."/home/niko/.config/systemd/user/sanitize-onedrive.timer".text = ''
[Unit]
Description=Run sanitize-onedrive every minute

[Timer]
# Run shortly after user session start, then every 15 seconds.
OnStartupSec=15s
OnUnitActiveSec=15s
AccuracySec=1s
Persistent=true

[Install]
WantedBy=timers.target
'';

  # Ensure the timer is enabled/started at home-manager activation. This runs
  # when the user's home configuration is applied (idempotent).
  home.activation.enableSanitizeOnedriveTimer = ''
    if command -v systemctl >/dev/null 2>&1; then
      # Reload user units and enable the timer
      systemctl --user daemon-reload || true
      systemctl --user enable --now sanitize-onedrive.timer || true
    fi
  '';
}
