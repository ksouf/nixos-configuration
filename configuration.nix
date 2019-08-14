{ config, pkgs, ... }:

{
  imports =
    [ 
      <nixos-hardware/dell/xps/13-9370>
      ./hardware-configuration.nix
      ./system-packages.nix
      ./users.nix
      ./specific-user.nix
      ./desktop/gnome-tools.nix
      ./desktop/i3.nix
      ./devices/luks.nix
      ./devices/audio.nix
      ./devices/bluetooth.nix
      ./devices/network.nix
      ./devices/usb-tools.nix
      ./documents-mgt/adope-reader.nix
      ./documents-mgt/libreoffice.nix
      ./documents-mgt/tex.nix
      ./profiles/git.nix
      ./shell/tilix.nix
      ./shell/zsh.nix
      ./social/slack.nix
      ./social/spotify.nix
      ./virtualization/docker.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system = {
  		autoUpgrade = {
  			enable = true;
  			dates = "13:00";
  		};
  	};
  i18n = {
     consoleFont = "Lat2-Terminus16";
     consoleKeyMap = "fr";
     defaultLocale = "fr_FR.UTF-8";
   };
   time.timeZone = "Europe/Paris";
}
