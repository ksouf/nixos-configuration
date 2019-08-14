{ config, pkgs, ... }:

{
	users = {
		mutableUsers = false; # when updating, set this to true, rebuild, then go back to false and rebuild and re change the password via passwd
		defaultUserShell = pkgs.zsh; # Make zsh default shell
		extraUsers = {
			khaled = {
				isNormalUser = true;
				uid = 1000;
				createHome = true;
				extraGroups = [ "networkmanager" "wheel" "docker" "dialout"];
				initialPassword = "changeMe";
			};
		};
	};
}
