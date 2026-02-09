{ config, pkgs, ... }:

{
  services.xserver = {
    xkb = {
      layout = "fr";
      variant = "oss";
    };
    inputClassSections = [
      ''
        Identifier      "TypeMatrix"
        MatchIsKeyboard "on"
        MatchVendor     "TypeMatrix.com"
        MatchProduct    "USB Keyboard"
        Driver          "evdev"
        Option          "XkbModel"      "tm2030USB"
        Option          "XkbLayout"     "fr"
        Option          "XkbVariant"    "bepo"
      ''
      ''
        Identifier      "Ergodox"
        MatchIsKeyboard "on"
        MatchUSBID      "feed:1307"
        Driver          "evdev"
        Option          "XkbLayout"     "fr"
        Option          "XkbVariant"    "bepo"
      ''
    ];
  };

  # Media keys handled by desktop environment (GNOME)
}
