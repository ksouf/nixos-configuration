{ config, pkgs, ... }:
let unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  environment.systemPackages = with pkgs; [
    #unstable.jdk
    #unstable.ruby
    unstable.turbo
    unstable.chromium
    unstable.pandoc
    unstable.nodejs_22
    unstable.playwright
    unstable.pnpm
    #unstable.python3
    #unstable.maven
    #blogging
    #jekyll
    #bundler
    #ruby
    #AWS
    #unstable.awscli2
    #unstable.aws-vault
    unstable.claude-code
    unstable.yarn
    openssl #needed for claude learning 
    prisma-engines
  ];

    environment.variables = {
    PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
    PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
  };
}
