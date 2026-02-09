{ config, pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages = [
    pkgs-unstable.darktable
    pkgs-unstable.drawio
    pkgs-unstable.gtk3-x11
  ];
}
