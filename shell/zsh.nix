{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    promptInit = "";
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker"];
    };
    interactiveShellInit = ''
        export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/

        # Customize your oh-my-zsh options here
        ZSH_THEME="agnoster"
        plugins=(git sudo docker)
        source $ZSH/oh-my-zsh.sh
        '';
  };
}
