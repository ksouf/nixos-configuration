{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.jetbrains.idea
    pkgs-unstable.vscode
    pkgs-unstable.doctl
  ];
}

