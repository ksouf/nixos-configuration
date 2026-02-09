{
  description = "NixOS configuration for Dell XPS 13 9370 (hanibal)";

  inputs = {
    # Stable nixpkgs (matching current channel nixos-25.11)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Unstable nixpkgs for newer packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hardware quirks database
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";

      # Create unstable package set
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

    in
    {
      nixosConfigurations.hanibal = nixpkgs.lib.nixosSystem {
        inherit system;

        # Pass special arguments to all modules
        specialArgs = {
          inherit inputs pkgs-unstable;
        };

        modules = [
          # Hardware-specific configuration from nixos-hardware
          nixos-hardware.nixosModules.dell-xps-13-9370

          # Main configuration
          ./configuration.nix
        ];
      };

      # Development shell for working on this flake
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = with nixpkgs.legacyPackages.${system}; [
          nil           # Nix LSP
          nixfmt-rfc-style  # Official Nix formatter
        ];
      };
    };
}
