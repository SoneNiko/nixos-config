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
    };
  };

  
  home.packages = with pkgs; [
    
  ];
}
