{ config, pkgs, ... }:

{
  # Kernel modules and parameters
  boot.kernelModules = [
    "snd-hda-intel"
    "snd-hda-codec-hdmi"
  ];

  boot.kernelParams = [
    "snd-hda-intel.model=generic"
    "snd-hda-intel.probe_mask=1"
  ];

  # Sound configuration
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable firmware
  hardware.enableRedistributableFirmware = true;

  # Diagnostic packages
  environment.systemPackages = with pkgs; [
    alsa-utils
    pavucontrol
    pipewire
    wireplumber
  ];
}