{ config, pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = [
    # pkgs-unstable.jdk
    # pkgs-unstable.ruby
    pkgs-unstable.turbo
    pkgs-unstable.chromium
    pkgs-unstable.pandoc
    pkgs-unstable.nodejs_22
    pkgs-unstable.playwright
    pkgs-unstable.pnpm
    # pkgs-unstable.python3
    # pkgs-unstable.maven
    # blogging
    # jekyll
    # bundler
    # ruby
    # AWS
    # pkgs-unstable.awscli2
    # pkgs-unstable.aws-vault
    # Infrastructure
    pkgs-unstable.terraform
    pkgs-unstable.claude-code
    pkgs-unstable.yarn
    pkgs.openssl         # needed for claude learning
    pkgs.prisma-engines
  ];

  environment.variables = {
    PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
    PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
    # Playwright uses system Chromium instead of downloading its own
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs-unstable.chromium}/bin/chromium";
  };
}
