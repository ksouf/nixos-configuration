{ config, pkgs, ... }:

{ #to be moved to home-manager
        profiles.git.enable = true;
	environment = {
		systemPackages = with pkgs; [
          git
          maven
          openjdk
          jetbrains.jdk # jdk optimized as a boot jdk for intellij
          adoptopenjdk-bin
          nodejs-10_x
          gtk3-x11
          firefox-esr
          google-chrome
		];
	};
}
