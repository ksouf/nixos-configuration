{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable._1password-cli
    pkgs-unstable._1password-gui
  ];
}
