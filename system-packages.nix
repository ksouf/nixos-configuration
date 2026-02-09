{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      # Nix tools
      cachix
      nixfmt-classic

      # Shell utilities
      direnv
      file
      tmux
      tree
      wget

      # System monitoring
      htop
      btop
      iotop
      lsof
      psmisc
      pv

      # Modern CLI replacements
      ripgrep     # Better grep
      fd          # Better find
      bat         # Better cat
      eza         # Better ls
      duf         # Better df
      dust        # Better du
      delta       # Better diff
      fzf         # Fuzzy finder
      zoxide      # Better cd

      # Hardware diagnostics
      pciutils    # lspci
      usbutils    # lsusb

      # Network tools
      netcat
      iw          # Wireless tools

      # Editor
      vim
    ];
  };

  # Enable direnv integration
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
