{ config, pkgs, lib, ... }:

{
	environment = {
		variables = {
			EDITOR = lib.mkForce "vim";
                        TERMINAL = [ "tilix" ];
		};
		systemPackages = with pkgs; [
           tilix
		];
	};
}

