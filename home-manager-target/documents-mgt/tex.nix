{ config, pkgs, ... }:

{
	environment = {
		systemPackages = with pkgs; [
           texmaker # for resume LateX
           texlive.combined.scheme-full
		];
	};

}

