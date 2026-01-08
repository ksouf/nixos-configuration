{ config, pkgs, ... }:

{
  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    git
    gh          # GitHub CLI
    git-lfs     # Large file support
  ];
}
