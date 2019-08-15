{ config, pkgs, ... }:

{
  imports =
    [ 
      <nixos-hardware/dell/xps/13-9370>
      ./hardware-configuration.nix
      ./system-packages.nix
      ./users.nix
      ./desktop/gnome-tools.nix
      ./desktop/i3.nix
      ./devices/luks.nix
      ./devices/audio.nix
      ./devices/bluetooth.nix
      ./devices/network.nix
      ./devices/usb-tools.nix
      ./shell/tilix.nix
      ./shell/zsh.nix
      ./virtualization/docker.nix
      ./home-manager-target/documents-mgt/libreoffice.nix
      ./home-manager-target/documents-mgt/tex.nix
      ./home-manager-target/profiles/git.nix
      ./home-manager-target/documents-mgt/adope-reader.nix
      ./home-manager-target/social/slack.nix
      ./home-manager-target/social/spotify.nix
      ./home-manager-target/ide.nix
      ./home-manager-target/browsers.nix
      ./home-manager-target/user-applications.nix
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

   #fixes Bug on rebuild
   system.stateVersion = "19.03";
}
