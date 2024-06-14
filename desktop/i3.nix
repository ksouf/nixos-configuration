{ config, pkgs, ... }:

{
	services = {
	    displayManager.defaultSession = "none+i3";
		xserver = {
			enable = true;
            xkb.layout = "fr";
            desktopManager = {
              xterm.enable = false;
            };

			windowManager = {
				i3 = {
				    enable = true;
                    extraPackages = with pkgs; [
                         dmenu
                         i3status
                         i3lock-fancy
                      ];
				};
			};
		};
	};
    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;
      packages = with pkgs; [
              corefonts
              dejavu_fonts
              emojione
              feh
              fira
              fira-code
              fira-code-symbols
              fira-mono
              hasklig
              inconsolata
              iosevka
              overpass
              symbola
              source-code-pro
              ubuntu_font_family
              unifont
      ];
    };
}
