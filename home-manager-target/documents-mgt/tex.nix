{ config, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in
{
	environment = {
		systemPackages = with pkgs; [
           unstable.texmaker # for resume LateX
           unstable.texlive.combined.scheme-full
           unstable.biber #for bibiligraphy references
		];
	};

}

