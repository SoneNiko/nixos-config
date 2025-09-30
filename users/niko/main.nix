{ config, pkgs, ... }: {
  home.username = "niko";
  home.homeDirectory = "/home/niko";

  home.stateVersion = "25.05";

  programs.git = {
    enable = true;
    userName = "Nikolas Heise";
    userEmail = "nikolasheise683@gmail.com";
    lfs.enable = true;
    extraConfig = {
      push = { autoSetupRemote = true; };
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
  service.onedrive.enable = "true";

  programs.vivaldi = {
    nativeMessagingHosts = [
      pkgs.kdePackages.plasma-browser-integration
    ];
  };

  
  home.packages = with pkgs; [
    
  ];
}
