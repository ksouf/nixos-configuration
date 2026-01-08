{ config, pkgs, ... }:

{
  imports = [
    <nixos-hardware/dell/xps/13-9370>
    ./hardware-configuration.nix
    ./hardware.nix
    ./modules/security.nix
    ./system-packages.nix
    ./users.nix
    ./desktop/gnome.nix
    #./desktop/gnome-tools.nix
    #./desktop/i3.nix
    #./desktop/hyprland.nix
    ./devices/luks.nix
    ./devices/audio.nix
    ./devices/bluetooth.nix
    ./devices/network.nix
    ./devices/usb-tools.nix
    ./devices/firmware.nix
    ./devices/keyboards.nix
    ./shell/tilix.nix
    ./shell/zsh.nix
    ./home-manager-target/documents-mgt/libreoffice.nix
    ./home-manager-target/documents-mgt/tex.nix
    ./home-manager-target/social/discussion.nix
    #./home-manager-target/social/ms-teams.nix
    ./home-manager-target/social/spotify.nix
    ./home-manager-target/social/zoom.nix
    ./home-manager-target/security/1password.nix
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

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";

  };

  i18n.defaultLocale = "fr_FR.UTF-8";
  time.timeZone = "Europe/Paris";

  nixpkgs.config.allowUnfree = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # This value determines the NixOS release with which your system is compatible
  # Do not change unless you know what you're doing
  system.stateVersion = "25.11";
}
