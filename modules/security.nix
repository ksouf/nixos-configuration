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

  # Kernel hardening
  boot.kernel.sysctl = {
    # Restrict kernel pointer exposure
    "kernel.kptr_restrict" = 2;
    # Restrict dmesg access
    "kernel.dmesg_restrict" = 1;
    # Disable magic sysrq (except sync, remount ro, reboot)
    "kernel.sysrq" = 176;
    # Protect against SUID core dumps
    "fs.suid_dumpable" = 0;

    # Network hardening - prevent ICMP redirect attacks
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;
    "net.ipv4.conf.all.send_redirects" = false;
    # Strict reverse path filtering (anti-spoofing)
    "net.ipv4.conf.all.rp_filter" = 1;

    # BPF hardening
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;

    # Filesystem hardening
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
  };

  # Disable core dumps (prevent leaking sensitive memory)
  systemd.coredump.enable = false;

  # Modern D-Bus implementation (faster, more secure)
  services.dbus.implementation = "broker";

  # Fail2ban for SSH protection (optional, enable if exposed to internet)
  # services.fail2ban.enable = true;
}
