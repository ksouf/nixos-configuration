{ config, pkgs, ... }:
let unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  environment.systemPackages = with pkgs; [
    unstable.jdk
    unstable.ruby
    unstable.nodePackages_latest.nodejs
    unstable.python3
    #blogging
    jekyll
    bundler
    ruby
    #AWS
    unstable.awscli2
  ];
}
