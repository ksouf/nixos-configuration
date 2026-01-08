{ config, lib, pkgs, ... }:

{
  # ============================================
  # SECURITY HARDENING
  # ============================================

  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = true;
    # Add ports as needed:
    # allowedTCPPorts = [ 22 80 443 ];
    # allowedUDPPorts = [ ];
  };

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };

  # Boot security (UEFI)
  boot.loader.systemd-boot.editor = false;

  # Sudo configuration
  security.sudo = {
    wheelNeedsPassword = true;
    execWheelOnly = true;
  };

  # Kernel hardening (conservative - compatible with most software)
  boot.kernel.sysctl = {
    # Restrict kernel pointer exposure
    "kernel.kptr_restrict" = 2;
    # Restrict dmesg access
    "kernel.dmesg_restrict" = 1;
    # Disable magic sysrq (except sync, remount ro, reboot)
    "kernel.sysrq" = 176;
    # Protect against SUID core dumps
    "fs.suid_dumpable" = 0;
  };

  # Fail2ban for SSH protection (optional, enable if exposed to internet)
  # services.fail2ban.enable = true;
}
