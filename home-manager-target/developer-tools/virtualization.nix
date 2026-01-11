{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.docker-compose
    pkgs-unstable.kubectl
    pkgs-unstable.minikube
    pkgs-unstable.exoscale-cli
    pkgs-unstable.k9s
  ];

  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;
  users.groups.vboxusers.members = [ "khaled" ];
}
