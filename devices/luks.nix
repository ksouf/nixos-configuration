{ config, pkgs, ... }:

{
  boot.initrd.luks.devices = [
    {
       name = "root";
       device = "/dev/disk/by-uuid/fa7236b3-6f0a-41ea-bacb-7e09e7f75eff";
       preLVM = true;
    }
  ];
}