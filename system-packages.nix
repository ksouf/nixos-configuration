{ config, pkgs, ... }:

{
	environment = {
		systemPackages = with pkgs; [
				       cachix
                       direnv
                       file
                       htop
                       iotop
                       lsof
                       netcat
                       psmisc
                       pv
                       tmux
                       tree
                       vim
                       wget
                       git
                       xorg.xbacklight
		];
	};

   nixpkgs.config.allowUnfree = true;
}
