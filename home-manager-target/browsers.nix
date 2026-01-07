{ config, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
	environment.systemPackages = with pkgs; [
          unstable.google-chrome
          unstable.brave
          #unstable.arc-browser
	];
}
