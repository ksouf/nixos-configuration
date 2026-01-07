{ config, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in
{
	environment = {
		systemPackages = with pkgs; [
		  unstable._1password-cli
		  unstable._1password-gui
		];
	};
}
