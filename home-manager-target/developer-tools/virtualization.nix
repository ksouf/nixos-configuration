{ config, pkgs, pkgs-unstable ? null, ... }:
let
  unstable = if pkgs-unstable != null
    then pkgs-unstable
    else import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  environment.systemPackages = with pkgs; [
    unstable.docker-compose
    unstable.kubectl
    unstable.minikube
    unstable.exoscale-cli
    unstable.k9s
  ];

  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "khaled" ];
}
