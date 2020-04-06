{ config, pkgs, ... }:
{
    profiles.git.enable = true;
    environment.systemPackages = with pkgs; [
          git
	];
}
