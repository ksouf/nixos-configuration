{ config, pkgs, ... }:

{
  # Kernel modules and parameters for Intel HDA
  boot.kernelModules = [
    "snd-hda-intel"
    "snd-hda-codec-hdmi"
  ];

  boot.kernelParams = [
    "snd-hda-intel.model=generic"
    "snd-hda-intel.probe_mask=1"
  ];

  # Disable PulseAudio (using PipeWire)
  services.pulseaudio.enable = false;

  # PipeWire audio stack
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Real-time scheduling for audio
  security.rtkit.enable = true;

  # Enable firmware for audio codecs
  hardware.enableRedistributableFirmware = true;

  # Audio management tools
  environment.systemPackages = with pkgs; [
    alsa-utils
    pavucontrol
  ];
}