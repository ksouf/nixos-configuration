# NixOS Testing

## Trigger
Testing NixOS configurations, integration testing, CI/CD setup, or validating changes before deployment.

## Overview

NixOS testing methods:

| Method | Use Case | Speed |
|--------|----------|-------|
| `nix flake check` | Syntax and evaluation | Fast |
| `nixos-rebuild build` | Build without activating | Medium |
| `nixos-rebuild test` | Activate without boot entry | Medium |
| NixOS VM tests | Full integration tests | Slow |
| Interactive VMs | Manual testing | Slow |

---

## Basic Validation

### Syntax Check

```bash
# Check single file
nix-instantiate --parse configuration.nix

# Check all .nix files
find /etc/nixos -name "*.nix" -exec nix-instantiate --parse {} \;
```

### Flake Check

```bash
# Full flake validation
nix flake check

# Check specific system
nix flake check --system x86_64-linux

# Show what will be checked
nix flake show
```

### Evaluation

```bash
# Evaluate configuration
nix eval .#nixosConfigurations.myhost.config.system.build.toplevel

# Check specific option
nix eval .#nixosConfigurations.myhost.config.services.nginx.enable

# Interactive exploration
nix repl
> :lf .
> nixosConfigurations.myhost.config.services
```

---

## Build Testing

### Build Without Activating

```bash
# Build the system
nixos-rebuild build --flake .#myhost

# Check what changed
nvd diff /run/current-system result

# Or with nix directly
nix build .#nixosConfigurations.myhost.config.system.build.toplevel
```

### Test Activation

```bash
# Activate without adding boot entry (revert on reboot)
sudo nixos-rebuild test --flake .#myhost

# Dry run (show what would change)
nixos-rebuild dry-activate --flake .#myhost
```

### Diff Before Deploy

```bash
# Install nvd
nix profile install nixpkgs#nvd

# Build and compare
nix build .#nixosConfigurations.myhost.config.system.build.toplevel -o new-system
nvd diff /run/current-system ./new-system
```

---

## NixOS VM Tests

Full integration testing with virtual machines.

### Basic Test Structure

```nix
# tests/mytest.nix
{ pkgs, ... }:

pkgs.testers.runNixOSTest {
  name = "my-service-test";

  nodes = {
    # Define virtual machine(s)
    machine = { config, pkgs, ... }: {
      # NixOS configuration for the VM
      services.nginx.enable = true;
      networking.firewall.allowedTCPPorts = [ 80 ];
    };
  };

  testScript = ''
    # Python test script
    machine.start()
    machine.wait_for_unit("nginx.service")
    machine.succeed("curl -f http://localhost/")
  '';
}
```

### In Flake

```nix
# flake.nix
{
  outputs = { nixpkgs, ... }: {
    checks.x86_64-linux = {
      # Basic test
      mytest = nixpkgs.legacyPackages.x86_64-linux.testers.runNixOSTest {
        name = "mytest";
        nodes.machine = { ... }: {
          services.myservice.enable = true;
        };
        testScript = ''
          machine.wait_for_unit("myservice.service")
        '';
      };

      # Test from separate file
      nginx-test = import ./tests/nginx.nix {
        inherit (nixpkgs.legacyPackages.x86_64-linux) pkgs;
      };
    };
  };
}
```

```bash
# Run all checks
nix flake check

# Run specific test
nix build .#checks.x86_64-linux.mytest
```

### Multi-Machine Tests

```nix
{ pkgs, ... }:

pkgs.testers.runNixOSTest {
  name = "client-server-test";

  nodes = {
    server = { ... }: {
      services.nginx = {
        enable = true;
        virtualHosts."test" = {
          root = pkgs.writeTextDir "index.html" "Hello!";
        };
      };
      networking.firewall.allowedTCPPorts = [ 80 ];
    };

    client = { ... }: {
      environment.systemPackages = [ pkgs.curl ];
    };
  };

  testScript = ''
    # Start both machines
    start_all()

    # Wait for server
    server.wait_for_unit("nginx.service")
    server.wait_for_open_port(80)

    # Test from client
    client.succeed("curl -f http://server/")
  '';
}
```

### Test Script API

```python
# Machine methods
machine.start()                          # Start VM
machine.shutdown()                       # Graceful shutdown
machine.crash()                          # Force stop
machine.wait_for_unit("service.service") # Wait for systemd unit
machine.wait_for_open_port(80)           # Wait for port
machine.wait_until_succeeds("cmd")       # Retry until success
machine.succeed("cmd")                   # Run, fail if non-zero
machine.fail("cmd")                      # Run, fail if zero
machine.execute("cmd")                   # Run, return (status, output)
machine.wait_for_file("/path")           # Wait for file
machine.copy_from_host("src", "dst")     # Copy file to VM
machine.get_screen_text()                # OCR screen content

# Global functions
start_all()                              # Start all machines
join_all()                               # Wait for all to finish

# Subtest organization
with subtest("description"):
    machine.succeed("...")
```

### Complete Example

```nix
{ pkgs, ... }:

pkgs.testers.runNixOSTest {
  name = "web-app-test";

  nodes = {
    webserver = { config, pkgs, ... }: {
      imports = [ ./modules/webapp.nix ];

      services.webapp = {
        enable = true;
        port = 8080;
      };

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "webapp" ];
      };

      networking.firewall.allowedTCPPorts = [ 8080 ];
    };
  };

  testScript = ''
    import json

    webserver.start()

    with subtest("PostgreSQL starts"):
        webserver.wait_for_unit("postgresql.service")

    with subtest("Web app starts"):
        webserver.wait_for_unit("webapp.service")
        webserver.wait_for_open_port(8080)

    with subtest("Health check passes"):
        response = webserver.succeed("curl -s http://localhost:8080/health")
        assert json.loads(response)["status"] == "ok"

    with subtest("Can create user"):
        webserver.succeed("""
            curl -X POST http://localhost:8080/users \
                -H 'Content-Type: application/json' \
                -d '{"name": "test"}'
        """)

    with subtest("User persists in database"):
        webserver.succeed("sudo -u postgres psql webapp -c 'SELECT * FROM users'")
  '';
}
```

---

## Interactive VM Testing

### Build and Run VM

```bash
# Build VM
nix build .#nixosConfigurations.myhost.config.system.build.vm

# Run VM
./result/bin/run-myhost-vm

# With more memory
QEMU_OPTS="-m 4096" ./result/bin/run-myhost-vm

# With port forwarding
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-myhost-vm
```

### Interactive Test Driver

```bash
# Build interactive test driver
nix build .#checks.x86_64-linux.mytest.driverInteractive

# Run interactive session
./result/bin/nixos-test-driver

# In the Python shell
>>> start_all()
>>> machine.succeed("ls /")
>>> machine.screenshot("test.png")
```

### QEMU Options

```nix
# In your test or VM config
{
  virtualisation = {
    memorySize = 2048;  # MB
    cores = 2;
    graphics = true;    # Enable display
    qemu.options = [
      "-enable-kvm"
      "-cpu host"
    ];
  };
}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main]
  pull_request:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main

      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Check flake
        run: nix flake check

      - name: Build system
        run: |
          nix build .#nixosConfigurations.myhost.config.system.build.toplevel

      - name: Run tests
        run: |
          nix build .#checks.x86_64-linux.mytest -L
```

### GitLab CI

```yaml
# .gitlab-ci.yml
image: nixos/nix:latest

before_script:
  - nix-env -iA nixpkgs.git

check:
  script:
    - nix flake check

build:
  script:
    - nix build .#nixosConfigurations.myhost.config.system.build.toplevel

test:
  script:
    - nix build .#checks.x86_64-linux.mytest -L
```

### Hydra

```nix
# flake.nix
{
  outputs = { nixpkgs, ... }: {
    # Hydra jobset
    hydraJobs = {
      build = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system: {
        myhost = self.nixosConfigurations.myhost.config.system.build.toplevel;
      });

      tests = {
        x86_64-linux = self.checks.x86_64-linux;
      };
    };
  };
}
```

---

## Testing Strategies

### Unit Tests for Modules

```nix
# Test module options
{ pkgs, ... }:

pkgs.testers.runNixOSTest {
  name = "module-options-test";

  nodes.machine = {
    imports = [ ../modules/mymodule.nix ];

    mymodule = {
      enable = true;
      port = 9000;
      users = [ "alice" "bob" ];
    };
  };

  testScript = ''
    machine.wait_for_unit("mymodule.service")

    # Verify config was applied
    machine.succeed("grep 'port=9000' /etc/mymodule/config")
    machine.succeed("grep 'alice' /etc/mymodule/users")
  '';
}
```

### Integration Tests

```nix
# Test service interactions
{ pkgs, ... }:

pkgs.testers.runNixOSTest {
  name = "full-stack-test";

  nodes = {
    db = { ... }: {
      services.postgresql.enable = true;
    };

    api = { ... }: {
      services.myapi = {
        enable = true;
        database = "postgresql://db/myapp";
      };
    };

    web = { ... }: {
      services.nginx = {
        enable = true;
        virtualHosts."app" = {
          locations."/api" = {
            proxyPass = "http://api:8080";
          };
        };
      };
    };
  };

  testScript = ''
    start_all()

    db.wait_for_unit("postgresql.service")
    api.wait_for_unit("myapi.service")
    web.wait_for_unit("nginx.service")

    # End-to-end test
    web.succeed("curl -f http://localhost/api/health")
  '';
}
```

### Regression Tests

```nix
# Test that issues don't recur
{ pkgs, ... }:

pkgs.testers.runNixOSTest {
  name = "regression-123";

  nodes.machine = { ... }: {
    # Configuration that triggered bug #123
    services.problematic.enable = true;
  };

  testScript = ''
    machine.start()

    # Bug #123: Service would crash on startup
    machine.wait_for_unit("problematic.service")

    # Bug #123: Config file was malformed
    machine.succeed("grep 'correct-value' /etc/problematic/config")
  '';
}
```

---

## Debugging Tests

### Verbose Output

```bash
# Show build logs
nix build .#checks.x86_64-linux.mytest -L

# Keep build directory
nix build .#checks.x86_64-linux.mytest --keep-failed
```

### Interactive Debugging

```python
# In test script
import pdb; pdb.set_trace()  # Break into debugger

# Or use interactive driver
machine.shell_interact()  # Drop to shell in VM
```

### Screenshots

```python
# Capture screen state
machine.screenshot("before.png")
machine.succeed("some-command")
machine.screenshot("after.png")
```

### Serial Console

```python
# Watch console output
machine.wait_for_console_text("Starting nginx")
```

---

## Best Practices

### DO

1. **Test in CI** - Catch issues before deploy
2. **Use subtests** - Organize test output
3. **Test failure modes** - Verify error handling
4. **Keep tests fast** - Use minimal configs
5. **Test upgrades** - Verify migration paths

### DON'T

1. **Don't test everything in VMs** - Use unit tests where possible
2. **Don't hardcode IPs** - Use hostnames
3. **Don't skip flake check** - Fast and catches many issues
4. **Don't ignore test failures** - Fix or remove flaky tests

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `nix flake check` | Validate flake |
| `nixos-rebuild build` | Build without activating |
| `nixos-rebuild test` | Activate temporarily |
| `nix build .#checks...` | Run VM test |
| `./result/bin/run-*-vm` | Interactive VM |
| `nvd diff old new` | Show changes |

## Confidence
0.95 - Patterns from NixOS testing framework documentation.

## Sources
- [NixOS Manual - Testing](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- [nix.dev - Integration Testing](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html)
- [NixOS Wiki - VM Tests](https://wiki.nixos.org/wiki/NixOS_VM_tests)
