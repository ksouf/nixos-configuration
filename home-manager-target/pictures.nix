{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.darktable
  ];
}