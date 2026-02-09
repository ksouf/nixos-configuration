{ config, pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages = [
    pkgs-unstable.libreoffice-fresh
  ];
}
