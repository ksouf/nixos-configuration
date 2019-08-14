{ config, pkgs, ... }:

{
	environment = {
		systemPackages = with pkgs; [
          gnome3.defaultIconTheme
          gnome3.dconf
          gnome3.gsettings-desktop-schemas
          gnome3.gtk
          gnome3.vte
          gnome3.nautilus
		];
	};
	programs.dconf.enable = true;
}
