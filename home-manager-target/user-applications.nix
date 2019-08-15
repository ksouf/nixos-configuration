{ config, pkgs, ... }:

{
    profiles.git.enable = true;
	environment.systemPackages = with pkgs; [
          git
          maven
          openjdk
          adoptopenjdk-bin
          nodejs-10_x
          gtk3-x11
	];
}
