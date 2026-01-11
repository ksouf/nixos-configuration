# NixOS Laptop Optimization

## Trigger
Laptop configuration, power management, battery optimization, or hardware-specific tuning.

## Overview

Laptop optimization covers:
- Power management (TLP, auto-cpufreq)
- CPU governors and frequency scaling
- Battery health
- SSD optimization
- Thermal management
- Suspend/hibernate

---

## Power Management Tools

### Comparison

| Tool | Focus | Pros | Cons |
|------|-------|------|------|
| **TLP** | Battery life | Zero config, comprehensive | Static profiles |
| **auto-cpufreq** | CPU scaling | Dynamic, adaptive | CPU-only focus |
| **power-profiles-daemon** | GNOME integration | Desktop friendly | Less control |
| **powertop** | Analysis + tuning | Good diagnostics | Manual tuning |

**Important:** Only use ONE power management tool. They conflict!

---

## TLP (Recommended)

Most comprehensive, zero-config power management.

### Basic Setup

```nix
{ config, lib, pkgs, ... }:

{
  # Enable TLP
  services.tlp = {
    enable = true;
    settings = {
      # CPU settings
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Limit CPU on battery (0-100%)
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 50;  # Limit to 50% on battery

      # Platform profile (performance, balanced, low-power)
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };

  # Disable conflicting service
  services.power-profiles-daemon.enable = false;
}
```

### Battery Health (ThinkPads)

```nix
services.tlp.settings = {
  # Start charging when below 40%
  START_CHARGE_THRESH_BAT0 = 40;
  START_CHARGE_THRESH_BAT1 = 40;

  # Stop charging at 80%
  STOP_CHARGE_THRESH_BAT0 = 80;
  STOP_CHARGE_THRESH_BAT1 = 80;

  # Restore thresholds on shutdown/reboot
  RESTORE_THRESHOLDS_ON_BAT = 1;
};
```

### Advanced TLP Settings

```nix
services.tlp.settings = {
  # WiFi power saving
  WIFI_PWR_ON_AC = "off";
  WIFI_PWR_ON_BAT = "on";

  # Audio power saving
  SOUND_POWER_SAVE_ON_AC = 0;
  SOUND_POWER_SAVE_ON_BAT = 1;
  SOUND_POWER_SAVE_CONTROLLER = "Y";

  # PCIe power management
  PCIE_ASPM_ON_AC = "default";
  PCIE_ASPM_ON_BAT = "powersupersave";

  # Runtime power management
  RUNTIME_PM_ON_AC = "on";  # Disabled on AC
  RUNTIME_PM_ON_BAT = "auto";  # Enabled on battery

  # USB autosuspend
  USB_AUTOSUSPEND = 1;
  USB_EXCLUDE_BTUSB = 1;  # Don't suspend Bluetooth
  USB_EXCLUDE_PHONE = 1;  # Don't suspend phones

  # Disk settings
  DISK_DEVICES = "nvme0n1 sda";
  DISK_APM_LEVEL_ON_AC = "254 254";
  DISK_APM_LEVEL_ON_BAT = "128 128";
  DISK_SPINDOWN_TIMEOUT_ON_AC = "0 0";
  DISK_SPINDOWN_TIMEOUT_ON_BAT = "0 0";
  DISK_IOSCHED = "mq-deadline mq-deadline";

  # SATA power management
  SATA_LINKPWR_ON_AC = "med_power_with_dipm max_performance";
  SATA_LINKPWR_ON_BAT = "med_power_with_dipm min_power";
};
```

### TLP Diagnostics

```bash
# Show current settings
sudo tlp-stat

# Show battery info
sudo tlp-stat -b

# Show power source
sudo tlp-stat -s

# Show CPU info
sudo tlp-stat -p
```

---

## auto-cpufreq

Dynamic CPU frequency scaling based on load.

```nix
{ ... }:

{
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # Disable conflicting services
  services.tlp.enable = false;
  services.power-profiles-daemon.enable = false;
}
```

---

## Intel CPU Optimization

### Microcode Updates

```nix
{ ... }:

{
  hardware.cpu.intel.updateMicrocode = true;
}
```

### Intel Graphics

```nix
{ pkgs, ... }:

{
  # Modern Intel graphics driver
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver    # VAAPI
      vaapiIntel           # Older hardware
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Power saving (may cause issues on some hardware)
  boot.kernelParams = [
    "i915.enable_psr=1"      # Panel Self-Refresh
    "i915.enable_fbc=1"      # Framebuffer Compression
  ];
}
```

### Thermald

Proactive thermal management for Intel CPUs.

```nix
{ ... }:

{
  services.thermald.enable = true;
}
```

---

## AMD CPU Optimization

```nix
{ pkgs, ... }:

{
  hardware.cpu.amd.updateMicrocode = true;

  # AMD graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      amdvlk
      rocmPackages.clr.icd
    ];
  };

  # AMD-specific kernel params (if needed)
  boot.kernelParams = [
    "amd_pstate=active"  # AMD P-State driver (newer kernels)
  ];
}
```

---

## SSD Optimization

### TRIM

```nix
{ ... }:

{
  # Periodic TRIM (weekly by default)
  services.fstrim.enable = true;

  # Or configure interval
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
```

### Mount Options

```nix
{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "ext4";
    options = [
      "noatime"        # Don't update access times
      "nodiratime"     # Don't update directory access times
      "discard=async"  # Async TRIM (btrfs)
    ];
  };
}
```

### ZRAM Swap

Compressed RAM swap (reduces SSD wear).

```nix
{ ... }:

{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;  # Use 50% of RAM for zram
  };
}
```

---

## Suspend and Hibernate

### Basic Setup

```nix
{ ... }:

{
  # Enable suspend/hibernate
  powerManagement.enable = true;

  # Resume from hibernation
  boot.resumeDevice = "/dev/disk/by-uuid/YOUR-SWAP-UUID";
}
```

### Lid Switch Actions

```nix
{ ... }:

{
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "ignore";

    extraConfig = ''
      HandlePowerKey=suspend
      IdleAction=suspend
      IdleActionSec=15min
    '';
  };
}
```

### Hibernate on Low Battery

```nix
{ ... }:

{
  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
    percentageCritical = 5;
    percentageAction = 3;
  };
}
```

---

## Display Backlight

```nix
{ pkgs, ... }:

{
  # Hardware backlight control
  hardware.acpilight.enable = true;

  # User permissions
  users.users.myuser.extraGroups = [ "video" ];

  # Backlight control utilities
  environment.systemPackages = with pkgs; [
    brightnessctl
    light
  ];

  # Preserve backlight on boot
  services.illum.enable = true;

  # Or use this for more control
  programs.light.enable = true;
}
```

---

## WiFi Power Management

```nix
{ ... }:

{
  # NetworkManager power saving
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;  # Enable WiFi power saving
  };

  # Or disable if causing issues
  # networking.networkmanager.wifi.powersave = false;
}
```

---

## Complete Laptop Configuration

```nix
# hardware/laptop.nix
{ config, lib, pkgs, ... }:

{
  # Power management
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_MAX_PERF_ON_BAT = 60;

      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;

      WIFI_PWR_ON_BAT = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  services.power-profiles-daemon.enable = false;

  # Intel specific
  hardware.cpu.intel.updateMicrocode = true;
  services.thermald.enable = true;

  # SSD optimization
  services.fstrim.enable = true;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Suspend/hibernate
  powerManagement.enable = true;
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  # Low battery hibernate
  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
  };

  # Backlight
  hardware.acpilight.enable = true;
  programs.light.enable = true;

  # Network power saving
  networking.networkmanager.wifi.powersave = true;
}
```

---

## Hardware-Specific Modules

### NixOS Hardware Repository

```nix
# flake.nix
{
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";

  outputs = { nixpkgs, nixos-hardware, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      modules = [
        # Pick your laptop model
        nixos-hardware.nixosModules.dell-xps-13-9370
        # nixos-hardware.nixosModules.lenovo-thinkpad-x1-carbon-gen10
        # nixos-hardware.nixosModules.framework-13-7040-amd
        ./configuration.nix
      ];
    };
  };
}
```

### Common Models

```nix
# Dell XPS
nixos-hardware.nixosModules.dell-xps-13-9370
nixos-hardware.nixosModules.dell-xps-15-9560

# Lenovo ThinkPad
nixos-hardware.nixosModules.lenovo-thinkpad-x1-carbon-gen10
nixos-hardware.nixosModules.lenovo-thinkpad-t480

# Framework
nixos-hardware.nixosModules.framework-13-7040-amd
nixos-hardware.nixosModules.framework-16-7040-amd

# Apple
nixos-hardware.nixosModules.apple-macbook-pro-14-1
```

---

## Diagnostics

### Battery

```bash
# Battery status
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# TLP battery info
sudo tlp-stat -b

# Charging thresholds
cat /sys/class/power_supply/BAT0/charge_control_start_threshold
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
```

### Power Consumption

```bash
# Install powertop
nix-shell -p powertop

# Run analysis (needs root)
sudo powertop

# Generate HTML report
sudo powertop --html=report.html
```

### CPU

```bash
# CPU frequency
watch -n 1 "grep MHz /proc/cpuinfo"

# CPU governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Turbo boost
cat /sys/devices/system/cpu/intel_pstate/no_turbo
```

### Thermal

```bash
# CPU temperatures
sensors

# Or with lm-sensors
watch -n 1 sensors
```

---

## Troubleshooting

### WiFi Keeps Disconnecting

```nix
# Disable WiFi power saving
networking.networkmanager.wifi.powersave = false;

# Or via TLP
services.tlp.settings = {
  WIFI_PWR_ON_AC = "off";
  WIFI_PWR_ON_BAT = "off";
};
```

### USB Devices Not Working

```nix
services.tlp.settings = {
  USB_AUTOSUSPEND = 0;  # Disable USB autosuspend
  # Or exclude specific devices
  USB_DENYLIST = "1234:5678";  # vendor:product ID
};
```

### Short Battery Life

```bash
# Check what's consuming power
sudo powertop

# Look for devices not in power saving mode
```

### Suspend Not Working

```bash
# Check what's blocking suspend
cat /sys/power/pm_async
systemctl status systemd-suspend.service

# Try different suspend method
echo deep > /sys/power/mem_sleep
```

---

## Quick Reference

| Setting | AC | Battery |
|---------|-----|---------|
| CPU Governor | performance | powersave |
| CPU Max | 100% | 50-80% |
| Turbo | auto | never |
| WiFi Power Save | off | on |
| USB Autosuspend | off | on |
| Screen Brightness | 100% | 50% |

## Confidence
0.95 - Patterns from NixOS hardware modules and community experience.

## Sources
- [NixOS Wiki - Laptop](https://wiki.nixos.org/wiki/Laptop)
- [TLP Documentation](https://linrunner.de/tlp/)
- [nixos-hardware](https://github.com/NixOS/nixos-hardware)
- [ArchWiki - Power Management](https://wiki.archlinux.org/title/Power_management)
