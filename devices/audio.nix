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

  # Dell XPS 13 9370 audio codec issue - known kernel bug since 5.4
  # The internal codec (ALC256) often fails to initialize on boot
  # See: https://wiki.archlinux.org/title/Dell_XPS_13_(9370)
  # Workaround: Use USB audio (dock) or Bluetooth headphones
  boot.extraModprobeConfig = ''
    options snd_intel_dspcfg dsp_driver=1
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