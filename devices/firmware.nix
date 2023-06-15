{ config, pkgs, ... }:

{
  services.fwupd.enable = true; # firmware tool update usage: https://wiki.archlinux.org/index.php/Fwupd
  environment.systemPackages = with pkgs; [
     xorg.xbacklight #used by fwupd
  ];
}