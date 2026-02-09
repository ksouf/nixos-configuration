{ config, pkgs, lib, ... }:

{
  environment = {
    variables = {
      EDITOR = lib.mkForce "nvim";
      TERMINAL = "ghostty";
    };
    systemPackages = with pkgs; [
      ghostty
    ];
  };
}
