{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    dbus
  ];

  networking.hostName = "hanibal";
  networking.extraHosts = "127.0.0.1 nixos";
  # SSH configuration moved to modules/security.nix
}
