{ config, pkgs, pkgs-unstable ? null, ... }:
let
  unstable = if pkgs-unstable != null
    then pkgs-unstable
    else import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
	environment.systemPackages = with pkgs; [
          unstable.google-chrome
          unstable.brave
          #unstable.arc-browser
	];
}
