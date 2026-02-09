{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.google-chrome
    pkgs-unstable.brave
    # pkgs-unstable.arc-browser
  ];
}
