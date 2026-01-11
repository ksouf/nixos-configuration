# Home Manager Integration Patterns

## Trigger
User-level configuration, dotfile management, or per-user package installation.

## Overview

Home Manager manages user environments declaratively, including:
- User packages (available only to specific users)
- Dotfiles and configuration files
- User services (systemd user units)
- Shell configuration
- Application settings

---

## Installation Methods

### Method 1: NixOS Module (Recommended)

Integrates Home Manager into your NixOS configuration:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.myuser = import ./home.nix;
        }
      ];
    };
  };
}
```

**Advantages:**
- Single `nixos-rebuild switch` updates everything
- System and user config in one place
- Shared nixpkgs instance

### Method 2: Standalone

Separate from NixOS, managed independently:

```bash
# Install
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# Apply changes
home-manager switch
```

**Advantages:**
- Works on non-NixOS (macOS, other Linux)
- Independent version control
- User can manage without sudo

---

## Configuration Structure

### Basic home.nix

```nix
{ config, pkgs, ... }:

{
  # User info
  home.username = "myuser";
  home.homeDirectory = "/home/myuser";

  # Home Manager version (required)
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # User packages
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    htop
  ];
}
```

### Recommended Structure

```
home/
├── default.nix           # Main entry, imports others
├── packages.nix          # User packages
├── shell/
│   ├── default.nix
│   ├── zsh.nix
│   ├── bash.nix
│   └── starship.nix
├── programs/
│   ├── default.nix
│   ├── git.nix
│   ├── neovim.nix
│   └── vscode.nix
├── services/
│   ├── default.nix
│   └── syncthing.nix
└── desktop/
    ├── default.nix
    ├── gnome.nix
    └── gtk.nix
```

---

## Common Program Configurations

### Git

```nix
{ config, ... }:

{
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };

    aliases = {
      co = "checkout";
      ci = "commit";
      st = "status";
      br = "branch";
      lg = "log --oneline --graph --decorate";
    };

    # Delta for better diffs
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };

    # Sign commits with SSH key
    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
    extraConfig.gpg.format = "ssh";
  };
}
```

### Zsh

```nix
{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -la";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      gc = "nix-collect-garbage -d";
    };

    initExtra = ''
      # Custom init
      bindkey -e  # Emacs keybindings
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" ];
      theme = "robbyrussell";
    };

    # Or use Starship instead
    # programs.starship.enable = true;
  };
}
```

### Neovim

```nix
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      # Theme
      tokyonight-nvim

      # LSP
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp

      # Treesitter
      (nvim-treesitter.withPlugins (p: [
        p.nix p.lua p.python p.rust p.go p.typescript
      ]))

      # File navigation
      telescope-nvim
      nvim-tree-lua

      # Git
      gitsigns-nvim
    ];

    extraLuaConfig = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true

      vim.g.mapleader = " "

      -- Theme
      vim.cmd.colorscheme("tokyonight")
    '';
  };
}
```

### VS Code

```nix
{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;  # or vscodium

    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      vscodevim.vim
      eamodio.gitlens
      ms-python.python
      rust-lang.rust-analyzer
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "remote-ssh";
        publisher = "ms-vscode-remote";
        version = "0.107.0";
        sha256 = "...";  # nix-prefetch-url
      }
    ];

    userSettings = {
      "editor.fontSize" = 14;
      "editor.fontFamily" = "'JetBrains Mono', monospace";
      "editor.formatOnSave" = true;
      "workbench.colorTheme" = "Tokyo Night";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
    };

    keybindings = [
      {
        key = "ctrl+h";
        command = "workbench.action.navigateLeft";
      }
    ];
  };
}
```

### Tmux

```nix
{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    mouse = true;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
        '';
      }
    ];

    extraConfig = ''
      # Split panes with | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
  };
}
```

---

## Managing Dotfiles

### Method 1: home.file

```nix
{ config, ... }:

{
  # Copy file from store
  home.file.".config/myapp/config.toml".source = ./dotfiles/myapp.toml;

  # Generate file content
  home.file.".config/myapp/settings.json".text = builtins.toJSON {
    theme = "dark";
    fontSize = 14;
  };

  # Recursive directory copy
  home.file.".config/nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };

  # Symlink (for configs that need to be writable)
  home.file.".local/share/myapp" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/myapp";
  };
}
```

### Method 2: XDG Directories

```nix
{ config, ... }:

{
  xdg = {
    enable = true;

    # XDG base directories
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";

    # XDG user directories
    userDirs = {
      enable = true;
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      pictures = "${config.home.homeDirectory}/Pictures";
    };

    # Config files using xdg.configFile
    configFile."myapp/config.toml".source = ./myapp.toml;
  };
}
```

---

## User Services

### Custom Systemd Service

```nix
{ config, pkgs, ... }:

{
  systemd.user.services.mybackup = {
    Unit = {
      Description = "My Backup Service";
      After = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${pkgs.restic}/bin/restic backup ~/Documents";
      Environment = [
        "RESTIC_REPOSITORY=s3:..."
        "RESTIC_PASSWORD_FILE=%h/.config/restic/password"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # With timer
  systemd.user.timers.mybackup = {
    Unit.Description = "Run backup daily";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
```

### Built-in Services

```nix
{ config, ... }:

{
  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  services.ssh-agent.enable = true;

  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrains Mono 10";
        frame_width = 2;
        frame_color = "#89b4fa";
      };
    };
  };
}
```

---

## Desktop Environment Integration

### GTK Theme

```nix
{ config, pkgs, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name = "Catppuccin-Mocha-Standard-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        variant = "mocha";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Catppuccin-Mocha-Dark-Cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 24;
    };

    font = {
      name = "Inter";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt to follow GTK theme
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  # Set cursor in X
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Catppuccin-Mocha-Dark-Cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
  };
}
```

### GNOME Settings

```nix
{ config, lib, ... }:

{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-format = "24h";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
      ];
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Nautilus.desktop"
        "code.desktop"
        "org.gnome.Terminal.desktop"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "gnome-terminal";
      name = "Terminal";
    };
  };
}
```

---

## Multi-User Setup

### Shared Configuration

```nix
# flake.nix
{
  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      # Shared home-manager config
      commonHomeConfig = {
        programs.git.enable = true;
        programs.zsh.enable = true;
        programs.starship.enable = true;
      };
    in {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # User: alice
            home-manager.users.alice = { ... }: {
              imports = [ commonHomeConfig ];
              home.username = "alice";
              home.homeDirectory = "/home/alice";
              home.stateVersion = "24.11";

              # Alice-specific settings
              programs.git.userName = "Alice";
              programs.git.userEmail = "alice@example.com";
            };

            # User: bob
            home-manager.users.bob = { ... }: {
              imports = [ commonHomeConfig ];
              home.username = "bob";
              home.homeDirectory = "/home/bob";
              home.stateVersion = "24.11";

              # Bob-specific settings
              programs.git.userName = "Bob";
              programs.git.userEmail = "bob@example.com";
            };
          }
        ];
      };
    };
}
```

---

## Best Practices

### DO

1. **Use `home.stateVersion`** - Don't change after initial setup
2. **Use `useGlobalPkgs`** - Avoid duplicate nixpkgs evaluation
3. **Split configuration** - One file per program/concern
4. **Use program modules** - Not raw home.file when possible
5. **Let Home Manager manage shell** - For proper PATH setup

### DON'T

1. **Don't mix nix-env and Home Manager** - Pick one
2. **Don't manually edit managed files** - They'll be overwritten
3. **Don't forget stateVersion** - Required field
4. **Don't use absolute paths** - Use `config.home.homeDirectory`

---

## Useful Options Reference

```nix
# Find Home Manager options
home-manager option programs.git
home-manager option services.syncthing

# Search options
nix search home-manager programs
```

## Confidence
0.95 - Patterns from Home Manager documentation and community usage.

## Sources
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager)
