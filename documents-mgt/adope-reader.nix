{ config, pkgs, ... }:

{
	environment = {
		systemPackages = with pkgs; [
          adobe-reader
		];
	};
}

