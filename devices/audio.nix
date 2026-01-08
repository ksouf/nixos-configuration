{ config, pkgs, lib, ... }:

{
  # Audio modules are auto-loaded - explicit loading not needed
  # Do NOT set snd-hda-intel.model or probe_mask - breaks codec detection

  # Disable PulseAudio completely (using PipeWire)
  services.pulseaudio.enable = lib.mkForce false;

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

  # Enable firmware for audio codecs (including SOF for Intel)
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [
    sof-firmware        # Sound Open Firmware for modern Intel laptops
    alsa-firmware
  ];

  # Prevent audio cutouts when idle (power saving can cause issues)
  boot.extraModprobeConfig = ''
    options snd-hda-intel power_save=0
  '';

  # Audio management tools
  environment.systemPackages = with pkgs; [
    alsa-utils          # aplay, arecord, alsamixer
    pavucontrol         # GTK volume control
    pulseaudio          # For pactl commands (compatible with PipeWire)
    helvum              # PipeWire patchbay (optional)
  ];
}