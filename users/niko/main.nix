{ config, pkgs, android-nixpkgs, ... }: {
  home.username = "niko";
  home.homeDirectory = "/home/niko";

  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
    BROWSER = "vivaldi";
    TERMINAL = "ghostty";
    JAVA_HOME = "/home/niko/.jdks/corretto-24.0.2/";
    ANDROID_HOME = "${config.home.homeDirectory}/.nix-profile/share/android-sdk";
    ANDROID_SDK_ROOT = "${config.home.homeDirectory}/.nix-profile/share/android-sdk";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    # bashrcExtra = 
    #   ''
        
    #   '';
    shellAliases = {
      ls = "lsd";
      la = "lsd -la";
      l = "lsd -l";
    };
    
  };

  # environment.pathsToLink = [ "/share/bash-completion" ];

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
    # Android SDK from android-nixpkgs
    (android-nixpkgs.sdk.x86_64-linux (sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-36-0-0
      platform-tools
      platforms-android-36
      emulator
      sources-android-36
      # Add more packages as needed:
      # build-tools-33-0-3
      # platforms-android-33
      # system-images-android-34-google-apis-x86-64
    ]))
  ];
}
