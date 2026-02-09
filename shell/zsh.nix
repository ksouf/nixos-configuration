{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    promptInit = "";
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"              # Git aliases & completions (gst, gco, gp, gl, etc.)
        "sudo"             # Press Esc twice to prepend sudo
        "docker"           # Docker completions & aliases (dps, dex, dlog, etc.)
        "docker-compose"   # Docker Compose completions (dcu, dcd, dcl, etc.)
        "kubectl"          # Kubectl aliases & completions (k, kgp, kgs, kdp, etc.)
        "terraform"        # Terraform completions & aliases (tf, tfa, tfp, etc.)
        "node"             # Node.js completions
        "npm"              # npm completions & aliases
        "fzf"              # Ctrl+T file search, Ctrl+R history, Alt+C cd
        "zoxide"           # z/zi smart directory jumping
        "colored-man-pages" # Colorized man pages
      ];
    };
  };
}
