# NixOS Security Hardening Guide

## Trigger
Any security-related configuration, production deployments, or security audits.

## Quick Start: Hardened Profile

The fastest way to harden NixOS is importing the built-in hardened profile:

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/profiles/hardened.nix>
  ];
}
```

This enables:
- Hardened Linux kernel with extra patches
- Memory allocator protection (scudo)
- Kernel module loading restrictions
- AppArmor mandatory access control
- Various sysctl hardening

---

## Kernel Hardening

### Sysctl Settings

```nix
boot.kernel.sysctl = {
  # Hide kernel pointers from unprivileged users
  "kernel.kptr_restrict" = 2;

  # Restrict dmesg to root
  "kernel.dmesg_restrict" = 1;

  # Restrict eBPF
  "kernel.unprivileged_bpf_disabled" = 1;
  "net.core.bpf_jit_harden" = 2;

  # Restrict ptrace
  "kernel.yama.ptrace_scope" = 1;

  # Restrict kernel profiling
  "kernel.perf_event_paranoid" = 3;

  # Disable kexec
  "kernel.kexec_load_disabled" = 1;

  # Network hardening
  "net.ipv4.conf.all.rp_filter" = 1;
  "net.ipv4.conf.default.rp_filter" = 1;
  "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  "net.ipv4.conf.all.accept_redirects" = 0;
  "net.ipv4.conf.all.secure_redirects" = 0;
  "net.ipv4.conf.all.send_redirects" = 0;
  "net.ipv6.conf.all.accept_redirects" = 0;
};
```

### Kernel Parameters

```nix
boot.kernelParams = [
  # Disable legacy vsyscall
  "vsyscall=none"

  # Enable IOMMU
  "iommu=force"

  # Disable hibernation (can leak keys)
  "nohibernate"
];
```

### Disable Kernel Modules

```nix
boot.blacklistedKernelModules = [
  # Obscure network protocols
  "dccp" "sctp" "rds" "tipc"

  # Obscure filesystems
  "cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "squashfs" "udf"

  # Disable Firewire (DMA attacks)
  "firewire-core" "firewire-ohci" "firewire-sbp2"

  # Disable Thunderbolt if not needed
  # "thunderbolt"
];
```

---

## Boot Security

### Disable Boot Editor

Prevent attackers with physical access from modifying boot parameters:

```nix
boot.loader.systemd-boot.editor = false;
```

### Secure Boot (Experimental)

Use [Lanzaboote](https://github.com/nix-community/lanzaboote) for Secure Boot:

```nix
# In flake.nix inputs
lanzaboote.url = "github:nix-community/lanzaboote";

# In configuration
boot.loader.systemd-boot.enable = lib.mkForce false;
boot.lanzaboote = {
  enable = true;
  pkiBundle = "/etc/secureboot";
};
```

---

## SSH Hardening

### Basic SSH Security

```nix
services.openssh = {
  enable = true;

  settings = {
    # Disable root login
    PermitRootLogin = "no";

    # Disable password authentication
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;

    # Disable X11 forwarding
    X11Forwarding = false;

    # Disable TCP forwarding if not needed
    AllowTcpForwarding = false;

    # Disable agent forwarding if not needed
    AllowAgentForwarding = false;

    # Use only strong ciphers
    Ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
    ];

    # Use only strong MACs
    Macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
    ];

    # Use only strong key exchange
    KexAlgorithms = [
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
    ];
  };

  # Only allow specific users
  # allowUsers = [ "admin" ];

  # Extra config
  extraConfig = ''
    # Disconnect idle sessions
    ClientAliveInterval 300
    ClientAliveCountMax 2

    # Limit authentication attempts
    MaxAuthTries 3
  '';
};
```

### Fail2ban

```nix
services.fail2ban = {
  enable = true;
  maxretry = 3;
  bantime = "1h";

  jails = {
    sshd = {
      settings = {
        filter = "sshd[mode=aggressive]";
        maxretry = 3;
      };
    };
  };
};
```

---

## Firewall

### Basic Firewall

```nix
networking.firewall = {
  enable = true;

  # Default: deny all incoming
  allowedTCPPorts = [ ];
  allowedUDPPorts = [ ];

  # Allow specific ports
  # allowedTCPPorts = [ 22 80 443 ];

  # Allow port ranges
  # allowedTCPPortRanges = [
  #   { from = 8000; to = 8010; }
  # ];

  # Log denied packets (for debugging)
  logReversePathDrops = true;
  logRefusedConnections = true;

  # Allow ICMP ping (optional)
  # allowPing = true;

  # Extra rules
  extraCommands = ''
    # Rate limit SSH connections
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
  '';
};
```

### Per-Interface Rules

```nix
networking.firewall = {
  enable = true;

  interfaces = {
    "eth0" = {
      allowedTCPPorts = [ 22 ];
    };
    "eth1" = {
      allowedTCPPorts = [ 80 443 ];
    };
  };
};
```

---

## User Security

### Sudo Configuration

```nix
security.sudo = {
  enable = true;

  # Require root password instead of user password
  # wheelNeedsPassword = true;

  extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  extraConfig = ''
    # Require TTY for sudo
    Defaults requiretty

    # Timeout after 5 minutes
    Defaults timestamp_timeout=5
  '';
};
```

### Password Policy

```nix
# Use strong password hashing
security.pam.services.passwd.text = ''
  password required pam_unix.so sha512 shadow rounds=65536
'';

# Require password for su
security.pam.services.su.requireWheel = true;
```

---

## Application Sandboxing

### Firejail

```nix
programs.firejail = {
  enable = true;

  wrappedBinaries = {
    firefox = {
      executable = "${pkgs.firefox}/bin/firefox";
      profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
    };

    chromium = {
      executable = "${pkgs.chromium}/bin/chromium";
      profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
    };

    vlc = {
      executable = "${pkgs.vlc}/bin/vlc";
      profile = "${pkgs.firejail}/etc/firejail/vlc.profile";
    };
  };
};
```

### Chromium SUID Sandbox

```nix
security.chromiumSuidSandbox.enable = true;
```

---

## Systemd Service Hardening

### Per-Service Hardening

```nix
systemd.services.myservice.serviceConfig = {
  # Filesystem restrictions
  ProtectSystem = "strict";      # Read-only /usr, /boot, /efi
  ProtectHome = true;            # No access to /home
  PrivateTmp = true;             # Private /tmp
  PrivateDevices = true;         # No device access
  ProtectKernelTunables = true;  # No /proc, /sys writes
  ProtectKernelModules = true;   # No module loading
  ProtectControlGroups = true;   # No cgroup modifications

  # Capability restrictions
  NoNewPrivileges = true;
  CapabilityBoundingSet = "";    # Drop all capabilities
  # Or specify needed caps:
  # CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

  # Namespace restrictions
  PrivateUsers = true;           # User namespace
  ProtectHostname = true;        # No hostname changes
  RestrictNamespaces = true;     # No new namespaces

  # System call filtering
  SystemCallFilter = [
    "@system-service"
    "~@privileged"
    "~@resources"
  ];
  SystemCallArchitectures = "native";

  # Memory protection
  MemoryDenyWriteExecute = true;

  # Network restrictions (if service doesn't need network)
  # PrivateNetwork = true;

  # Resource limits
  LimitNPROC = 64;
  LimitNOFILE = 1024;
};
```

### Analyze Service Security

```bash
# Check security score
systemd-analyze security myservice

# List all services with scores
systemd-analyze security
```

---

## Disk Encryption

### LUKS Full Disk Encryption

```nix
boot.initrd.luks.devices."cryptroot" = {
  device = "/dev/disk/by-uuid/YOUR-UUID";
  preLVM = true;
  allowDiscards = true;  # For SSD TRIM (slight security tradeoff)
};
```

### Encrypted Swap

```nix
swapDevices = [{
  device = "/dev/disk/by-uuid/YOUR-SWAP-UUID";
  randomEncryption = {
    enable = true;
    cipher = "aes-xts-plain64";
  };
}];
```

---

## Network Security

### DNS over TLS

```nix
services.resolved = {
  enable = true;
  dnssec = "true";
  domains = [ "~." ];
  fallbackDns = [ "1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" ];
  extraConfig = ''
    DNSOverTLS=yes
  '';
};

networking.nameservers = [ "127.0.0.53" ];
```

### OpenSnitch (Application Firewall)

```nix
services.opensnitch = {
  enable = true;
  rules = {
    "allow-firefox" = {
      name = "allow-firefox";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "simple";
        sensitive = false;
        operand = "process.path";
        data = "${pkgs.firefox}/bin/.firefox-wrapped";
      };
    };
  };
};
```

---

## Antivirus

### ClamAV

```nix
services.clamav = {
  daemon.enable = true;
  updater.enable = true;

  daemon.settings = {
    LogFile = "/var/log/clamd.log";
    LogTime = true;
    DetectPUA = true;
  };
};
```

---

## Audit Logging

### auditd

```nix
security.auditd.enable = true;
security.audit = {
  enable = true;
  rules = [
    # Log all commands run as root
    "-a exit,always -F arch=b64 -F euid=0 -S execve"

    # Log file deletions
    "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat"

    # Log permission changes
    "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat"

    # Log sudo usage
    "-w /etc/sudoers -p wa -k sudoers"
  ];
};
```

---

## Disable Unnecessary Features

```nix
# Disable core dumps
systemd.coredump.enable = false;

# Or restrict them
# systemd.coredump.extraConfig = ''
#   Storage=none
#   ProcessSizeMax=0
# '';

# Disable USB if not needed (extreme)
# boot.blacklistedKernelModules = [ "usb-storage" ];

# Disable webcam if not needed
# boot.blacklistedKernelModules = [ "uvcvideo" ];
```

---

## Security Checklist

### Critical
- [ ] Firewall enabled
- [ ] SSH: No root login, no password auth
- [ ] Boot editor disabled
- [ ] No plaintext secrets in config
- [ ] Disk encryption enabled

### Important
- [ ] Kernel sysctl hardened
- [ ] Fail2ban enabled
- [ ] Core dumps disabled
- [ ] Services use PrivateTmp, ProtectSystem

### Recommended
- [ ] Hardened profile imported
- [ ] Firejail for browsers
- [ ] DNS over TLS
- [ ] Audit logging enabled

---

## Complete Hardened Configuration Example

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/profiles/hardened.nix>
  ];

  boot = {
    loader.systemd-boot.editor = false;
    kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.fail2ban.enable = true;

  systemd.coredump.enable = false;

  programs.firejail.enable = true;
}
```

## Confidence
0.95 - Security best practices with some site-specific adjustments needed.

## Sources
- [NixOS Wiki - Security](https://wiki.nixos.org/wiki/Security)
- [Solene's Hardening Guide](https://dataswamp.org/~solene/2022-01-13-nixos-hardened.html)
- [nix-mineral](https://github.com/cynicsketch/nix-mineral)
- [NixOS Wiki - Systemd Hardening](https://nixos.wiki/wiki/Systemd_Hardening)
