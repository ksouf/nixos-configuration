{ config, pkgs, ... }:

{
	environment = {
		systemPackages = with pkgs; [
				       cachix
                       direnv #used for isloted environment directory
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
                       #fwupd #used for updating firmware
                       glib-networking.out #used by fwupd
		];
	};

   #systemd.packages = [ pkgs.fwupd ];

   nixpkgs.config.allowUnfree = true;
}
