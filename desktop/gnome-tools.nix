{ config, pkgs, ... }:

{
	environment = {
		systemPackages = with pkgs; [
          gnome.adwaita-icon-theme
          pkgs.dconf
          pkgs.gsettings-desktop-schemas
          pkgs.gtk3
          pkgs.vte
          gnome.nautilus
		];
	};
	programs.dconf.enable = true;
}
