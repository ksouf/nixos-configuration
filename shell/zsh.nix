{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    promptInit = "";
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "sudo" "docker" ];
    };
  };
}
