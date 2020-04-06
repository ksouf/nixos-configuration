
{ config, pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
      docker_compose
      minikube
      kubectl
      kubernetes-helm
    ];
  #  services.kubernetes = {
  #    roles = ["master" "node"];
  #    masterAddress = "localhost";
  #    easyCerts = true;
  #    kubelet.extraOpts = "--fail-swap-on=false";
  #    flannel.enable = true;
  #  };
    virtualisation.docker.enable = true;
    virtualisation.virtualbox.host.enable = true;
    users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];
}
