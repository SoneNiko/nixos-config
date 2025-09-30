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
    };
  };


  # https://github.com/abraunegg/onedrive/blob/master/config are the valid options
  programs.onedrive = {
    enable = true;
    settings = {
      cleanup_local_files = "true";
      display_running_config = "true";
      display_transfer_metrics = "true";
      enable_logging = "true";
      log_dir = "/var/log/onedrive/";
      notify_file_actions = "enable";
      recycle_bin_path = "/home/niko/.local/share/Trash/files/";
      sync_dir_permissions = "700";
      sync_file_permissions = "700";
      threads = "14";
    };
  };

  programs.vivaldi = {
    nativeMessagingHosts = [
      pkgs.kdePackages.plasma-browser-integration
    ];
  };

  
  home.packages = with pkgs; [
    
  ];
}
