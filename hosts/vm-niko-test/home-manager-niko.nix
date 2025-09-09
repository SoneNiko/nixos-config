{ config, pkgs, ... }: {
  home.username = "niko";
  home.homeDirectory = "/home/niko";

  programs.git = {
    enable = true;
    userName = "Nikolas Heise";
    userEmail = "nikolasheise683@gmail.com";
  };

  
  home.packages = with pkgs; [
    
  ];
}
