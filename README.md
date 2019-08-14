When installing nixos:

Don't forget you can access the nix installation manual by pressing ALT+F8

follow the nix installation manual until step 10
use nix-env -i git to get git in the shell
clone this repository in /etc/nixos
link configuration.nix to a known machine or create a new one
run nixos-generate-configuration to have the hardware-configuration.nix generated.