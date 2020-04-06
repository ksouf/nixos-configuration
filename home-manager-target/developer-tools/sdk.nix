{ config, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
          maven
          openjdk
          adoptopenjdk-bin
          nodejs-10_x
          python38Full
	];
}
