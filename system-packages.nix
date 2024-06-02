{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      cachix
      direnv # used for isloted environment directory
      file
      htop
      iotop
      lsof
      netcat
      psmisc
      pv
      tmux
      tree
      vim
      wget
      git
      nixfmt
    ];
  };

}
