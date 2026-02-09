{ config, pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages = [
    pkgs-unstable.turbo
    pkgs-unstable.chromium
    pkgs-unstable.pandoc
    pkgs-unstable.nodejs_22
    pkgs-unstable.playwright
    pkgs-unstable.pnpm
    pkgs-unstable.terraform
    pkgs-unstable.azure-cli
    pkgs-unstable.scaleway-cli
    pkgs-unstable.doctl
    pkgs-unstable.claude-code
    pkgs-unstable.yarn
    pkgs.openssl
    pkgs.prisma-engines
  ];

  environment.variables = {
    PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
    PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs-unstable.chromium}/bin/chromium";
  };
}
