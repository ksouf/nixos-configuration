{ config, lib, pkgs, ... }:

{
  # ============================================
  # HARDWARE-SPECIFIC CONFIGURATION
  # Generated based on detected hardware
  # Dell XPS 13 9370 - Intel Core i7-8550U
  # ============================================

  # Detected: vendor_id = GenuineIntel (Intel Core i7-8550U Kaby Lake)
  hardware.cpu.intel.updateMicrocode = true;

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
