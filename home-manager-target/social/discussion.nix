{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.slack
    pkgs-unstable.discord
  ];
}
