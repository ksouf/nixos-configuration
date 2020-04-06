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
      ./home-manager-target/documents-mgt/libreoffice.nix
      ./home-manager-target/documents-mgt/tex.nix
      ./home-manager-target/documents-mgt/adope-reader.nix
      ./home-manager-target/social/slack.nix
      ./home-manager-target/social/spotify.nix
      ./home-manager-target/social/zoom.nix
      ./home-manager-target/developer-tools/ide.nix
      ./home-manager-target/developer-tools/vcs.nix
      ./home-manager-target/developer-tools/sdk.nix
      ./home-manager-target/developer-tools/virtualization.nix
      ./home-manager-target/developer-tools/git-profile.nix
      ./home-manager-target/developer-tools/diagram.nix
      ./home-manager-target/browsers.nix
      ./home-manager-target/pictures.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.autoUpgrade.enable = true;

   console = {
     font = "Lat2-Terminus16";
     keyMap = "fr";

   };
   i18n.defaultLocale = "fr_FR.UTF-8";
   time.timeZone = "America/Montreal";

   #fixes Bug on rebuild
   system.stateVersion = "19.09";
}
