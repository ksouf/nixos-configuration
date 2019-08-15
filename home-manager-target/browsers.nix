{ config, pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
          firefox-esr
          google-chrome
	];
}
