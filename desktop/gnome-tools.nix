{ config, pkgs, ... }:

{
	environment = {
		systemPackages = with pkgs; [
          adwaita-icon-theme
          dconf
          gsettings-desktop-schemas
          gtk3
          vte
          nautilus
		];
	};
	programs.dconf.enable = true;
}
