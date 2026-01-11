{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.texmaker              # for resume LaTeX
    pkgs-unstable.texlive.combined.scheme-full
    pkgs-unstable.biber                 # for bibliography references
  ];
}

