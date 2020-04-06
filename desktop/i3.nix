{ config, pkgs, ... }:

{
	services = {
		xserver = {
			enable = true;
            layout = "fr";
            desktopManager = {
              xterm.enable = false;
            };
            displayManager.defaultSession = "none+i3";
			windowManager = {
				i3 = {
				    enable = true;
                    extraPackages = with pkgs; [
                         dmenu
                         i3status
                         i3lock-fancy
                         (python3Packages.py3status.overrideAttrs (oldAttrs: {
                               propagatedBuildInputs = [ python3Packages.pytz python3Packages.tzlocal python3Packages.toolz python3Packages.numpy];
                         }))
                      ];
				};
			};
		};
		fwupd = {
		  enable = true;
		};
	};
    fonts = {
      enableFontDir = true;
      enableGhostscriptFonts = true;
      fonts = with pkgs; [
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
