{ config, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
          (jetbrains.idea-ultimate.override { jdk = pkgs.jetbrains.jdk; })
          vscode
	];
}
