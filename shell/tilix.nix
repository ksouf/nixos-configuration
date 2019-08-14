{ config, pkgs, ... }:

{       
	environment = {
		variables = {
			EDITOR = pkgs.lib.mkOverride 0 "vim";
                        TERMINAL = [ "tilix" ];
		};
		systemPackages = with pkgs; [
           tilix
           python36Packages.powerline
           powerline-fonts
		];
	};
}

