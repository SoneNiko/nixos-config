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
    userName = "Nikolas Heise";
    userEmail = "nikolasheise683@gmail.com";
    lfs.enable = true;
    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      # Configure Commit Signing
      commit.gpgsign = true;
      user.signingkey = "891AFE673465C446";
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
}
