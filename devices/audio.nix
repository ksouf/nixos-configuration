{ config, pkgs, ... }:

{
 environment.systemPackages = with pkgs; [
   pavucontrol # GUI for audio management
   apulse
 ];

 hardware = {
   pulseaudio = {
     enable = true;
	 package = pkgs.pulseaudioFull; #used for my blutooth headset
   };
 };
}