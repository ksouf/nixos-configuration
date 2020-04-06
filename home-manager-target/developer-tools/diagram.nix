{ config, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
          gtk3-x11
          xmind
          drawio
	];
}
