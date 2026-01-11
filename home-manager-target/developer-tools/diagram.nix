{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.gtk3-x11
    pkgs-unstable.drawio
  ];
}
