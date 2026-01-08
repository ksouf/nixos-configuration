{ config, pkgs, ... }:

{
  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
    users.khaled = {
      isNormalUser = true;
      uid = 1000;
      createHome = true;
      extraGroups = [ "networkmanager" "wheel" "docker" "dialout" "video" "audio" ];
      initialPassword = "changeMe";
      # Consider using hashedPasswordFile for better security
    };
  };
}
