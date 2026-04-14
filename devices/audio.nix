{ config, pkgs, lib, ... }:

{
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

  # Enable firmware for audio codecs
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [
    sof-firmware
    alsa-firmware
  ];

  # Dell XPS 13 9370 — ALC256 codec initialization fix
  #
  # Problem: The Realtek ALC256 (codec address 0) fails to respond during
  # HDA bus enumeration, producing "spurious response 0x0:0x0" and
  # "no AFG or MFG node found". Only HDMI codec (address 2) loads.
  #
  # Fix: Force single_cmd mode (avoids CORB/RIRB timeout cascade),
  # disable MSI upfront, prevent power save during init,
  # and set Dell-specific pin mapping for ALC256.
  boot.extraModprobeConfig = ''
    options snd_intel_dspcfg dsp_driver=1
    options snd-hda-intel single_cmd=1 enable_msi=0 power_save=0 power_save_controller=N
    options snd-hda-intel model=dell-headset-multi
  '';

  # Systemd service: recover ALC3271 (ALC299) codec via PCI rebind if boot probe fails
  # On Dell XPS 9370, the codec often fails first probe but succeeds on PCI rebind
  systemd.services.hda-codec-reload = {
    description = "Recover ALC3271 codec via PCI rebind";
    after = [ "sound.target" "multi-user.target" "suspend.target" "hibernate.target" ];
    wantedBy = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    path = [ pkgs.kmod ];
    script = ''
      HDA_PCI="0000:00:1f.3"
      HDA_DRIVER="/sys/bus/pci/drivers/snd_hda_intel"
      max_retries=3
      retry=0

      while [ $retry -lt $max_retries ]; do
        # Check if ALC codec is present (codec#0 on any card)
        if ls /proc/asound/card*/codec#0 &>/dev/null; then
          echo "ALC3271 codec detected, no rebind needed"
          exit 0
        fi

        retry=$((retry + 1))
        echo "ALC3271 codec not found (attempt $retry/$max_retries), PCI rebind..."

        # Unbind and rebind the HDA PCI device (works even when module is in use)
        echo "$HDA_PCI" > "$HDA_DRIVER/unbind" 2>/dev/null || true
        sleep 2
        echo "$HDA_PCI" > "$HDA_DRIVER/bind" 2>/dev/null || true

        # Wait for codec enumeration
        sleep 3
      done

      # Final check
      if ls /proc/asound/card*/codec#0 &>/dev/null; then
        echo "ALC3271 codec recovered after PCI rebind"

        # Restart PipeWire/WirePlumber for all logged-in users
        ${pkgs.systemd}/bin/loginctl list-users --no-legend | while read uid user rest; do
          echo "Restarting PipeWire for user $user (uid $uid)"
          ${pkgs.systemd}/bin/systemctl --user -M "$user@.host" restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
        done
      else
        echo "WARNING: ALC3271 codec could not be recovered after $max_retries attempts"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Audio management tools
  environment.systemPackages = with pkgs; [
    alsa-utils
    pavucontrol
    pulseaudio          # For pactl commands (compatible with PipeWire)
    helvum
  ];
}
