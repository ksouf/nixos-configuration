{ config, pkgs, lib, ... }:

{
  networking.networkmanager.enable = true;

  networking.hostName = "hanibal";
  networking.extraHosts = "127.0.0.1 nixos";

  # Disable wait-online (unnecessary on laptop, saves ~10s boot time)
  systemd.services.NetworkManager-wait-online.enable = false;

  # Reload ath10k WiFi driver after suspend (fails to reinitialize on its own)
  systemd.services.wifi-resume = {
    description = "Reload ath10k WiFi after suspend";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    path = [ pkgs.kmod ];
    script = ''
      modprobe -r ath10k_pci && sleep 1 && modprobe ath10k_pci
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  # DNS privacy with systemd-resolved (DNS-over-TLS)
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" "9.9.9.9" "2606:4700:4700::1111" "2620:fe::fe" ];
    dnsovertls = "opportunistic";
  };
}
