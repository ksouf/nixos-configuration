{pkgs, ...}:
{
  programs.hyprland = {# or wayland.windowManager.hyprland
    enable = true;
    nvidiaPatches = true;
    xwayland.enable = true;
  };

  hardware = {
    # Opengl
    opengl.enable = true;

    # Most wayland compositors need this
    nvidia.modesetting.enable = true;
  };

  # XDG portal
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # sound.enable removed - deprecated since 24.05, PipeWire handles audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

    environment.systemPackages = with pkgs; [
                                        (pkgs.waybar.overrideAttrs (oldAttrs: {
                                            mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
                                            })
                                        )
                                        dunst
                                        libnotify
                                        swww
                                        rofi-wayland
                                  ];
}