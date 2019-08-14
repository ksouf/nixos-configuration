# Nixos configuration


## How to use

When installing nixos:

- follow the [nix installation manual](https://nixos.org/nixos/manual/index.html#sec-installation) until *step 10*
- use `nix-env -i git` to get git in the shell
- clone this repository in `/etc/nixos`
- link `configuration.nix` to a known machine or create a new one
- run `nixos-generate-configuration` to have the
  `hardware-configuration.nix` generated.
- modify the file `devices/luks.nix` specifying the `device` UUID
- Add and update `nixos-hardware` channel:
  ```
  $ sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
  $ sudo nix-channel --update nixos-hardware
  ```
- continue the [nix installation manual](https://nixos.org/nixos/manual/index.html#sec-installation)