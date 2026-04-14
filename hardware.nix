{ config, lib, pkgs, ... }:

{
  # ============================================
  # HARDWARE-SPECIFIC CONFIGURATION
  # Generated based on detected hardware
  # Dell XPS 13 9370 - Intel Core i7-8550U
  # ============================================

  # Detected: vendor_id = GenuineIntel (Intel Core i7-8550U Kaby Lake)
  hardware.cpu.intel.updateMicrocode = true;

  # Systemd in initrd for faster, more reliable boot
  boot.initrd.systemd.enable = true;

  # Distribute hardware interrupts across CPU cores
  services.irqbalance.enable = true;

  # Disable power-profiles-daemon (conflicts with TLP, enabled by nixos-hardware)
  services.power-profiles-daemon.enable = false;

  # Detected: MACHINE_TYPE = laptop (BAT0 present)
  # Intel CPU → thermald compatible
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      # Preserve battery longevity
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  services.thermald.enable = true;

  # Detected: NVMe SSD (476.9GB), filesystem = ext4
  services.fstrim.enable = true;

  # Nix store optimization
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Enable flakes and new nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Zram swap (16GB RAM detected - reduces SSD swap wear)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Desktop with zram: prefer zram over disk swap, reduce SSD writes
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Faster initrd decompression (default is gzip)
  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [ "-19" "-T0" ];

  # Dell XPS 9370: use Modern Standby (s2idle) instead of S3 deep sleep
  # S3 deep is broken on this hardware — causes failed resume / cold reboots
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "nvme.noacpi=1"
  ];

  # Reduce SSD writes: noatime on root
  fileSystems."/".options = [ "noatime" ];

  # Intel GPU - ensure proper graphics support
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
}
