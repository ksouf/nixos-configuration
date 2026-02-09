{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./modules/security.nix
    ./system-packages.nix
    ./users.nix
    ./desktop/gnome.nix
    ./devices/luks.nix
    ./devices/audio.nix
    ./devices/bluetooth.nix
    ./devices/network.nix
    ./devices/usb-tools.nix
    ./devices/firmware.nix
    ./devices/keyboards.nix
    ./shell/tilix.nix
    ./shell/zsh.nix
    ./apps/documents.nix
    ./apps/social.nix
    ./apps/security/1password.nix
    ./apps/developer-tools/ide.nix
    ./apps/developer-tools/sdk.nix
    ./apps/developer-tools/virtualization.nix
    ./apps/developer-tools/git.nix
    ./apps/browsers.nix
    ./apps/graphics.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  i18n.defaultLocale = "fr_FR.UTF-8";
  time.timeZone = "Europe/Paris";

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.flake = "/etc/nixos#hanibal";

  # This value determines the NixOS release with which your system is compatible
  # Do not change unless you know what you're doing
  system.stateVersion = "25.11";
}
