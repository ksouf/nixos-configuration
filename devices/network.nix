{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    openconnect
    networkmanager-openconnect
    networkmanagerapplet
    dbus
  ];

  networking.hostName = "hanibal";
  networking.extraHosts =  "127.0.0.1 nixos";
  services.openssh.enable = true;
}
