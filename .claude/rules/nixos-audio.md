# Rule: NixOS Audio Configuration

## Trigger
Modifications to `devices/audio.nix` or audio-related options

## Detection
Check for these audio configuration issues:

### Dangerous Kernel Parameters
These parameters should NOT be set as they can break codec detection:
- `snd-hda-intel.probe_mask=*` - blocks codec probing
- `snd-hda-intel.model=generic` - forces wrong model

### Required Components for PipeWire
- `services.pipewire.enable = true`
- `services.pipewire.alsa.enable = true`
- `services.pipewire.pulse.enable = true`
- `services.pipewire.wireplumber.enable = true`
- `security.rtkit.enable = true`

### PulseAudio Conflict
When using PipeWire, PulseAudio must be disabled:
- `services.pulseaudio.enable = lib.mkForce false`

### Intel Laptop Firmware
For Intel laptops, include:
- `sof-firmware` - Sound Open Firmware
- `alsa-firmware` - ALSA firmware

## Fix
Remove dangerous kernel params, ensure PipeWire is properly configured, disable PulseAudio when using PipeWire.

## Confidence
0.95 - Learned from fixing audio on this Dell XPS 13

## Examples
```nix
# Good - no probe_mask or model params
boot.extraModprobeConfig = ''
  options snd-hda-intel power_save=0
'';

# Bad - breaks codec detection
boot.kernelParams = [
  "snd-hda-intel.probe_mask=1"  # DON'T DO THIS
];
```
