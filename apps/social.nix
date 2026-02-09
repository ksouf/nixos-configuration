{ config, pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages = [
    pkgs-unstable.slack
    pkgs-unstable.discord
    pkgs-unstable.spotify
    pkgs-unstable.zoom-us
  ];
}
