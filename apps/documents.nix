{ config, pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages = [
    pkgs-unstable.libreoffice-fresh
    pkgs-unstable.texmaker
    pkgs-unstable.texlive.combined.scheme-full
    pkgs-unstable.biber
  ];
}
