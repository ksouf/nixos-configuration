# NixOS Secrets Management

## Trigger
Any configuration involving passwords, API keys, tokens, certificates, or sensitive data.

## The Problem

NixOS configurations are stored in the world-readable `/nix/store`. This means:

```nix
# NEVER DO THIS - secret visible to all users!
services.myservice.password = "supersecret123";
```

The secret will be stored unencrypted at:
```
/nix/store/xxxxx-nixos-system-.../etc/myservice.conf
```

---

## Solution Overview

Secret management tools encrypt secrets at rest and decrypt them at runtime to restricted locations (typically `/run/secrets/`).

| Tool | Encryption | Key Type | Best For |
|------|-----------|----------|----------|
| **sops-nix** | age/GPG/KMS | SSH, age, cloud KMS | Production, flexibility |
| **agenix** | age | SSH keys | Simple setups |
| **git-crypt** | GPG | GPG keys | Quick & dirty (not recommended) |
| **ragenix** | age | SSH keys | Rust alternative to agenix |

---

## sops-nix (Recommended)

### Why sops-nix?

- Multiple encryption backends (age, GPG, cloud KMS)
- Template support for embedding secrets in config files
- Works with existing SSH keys
- Active development and community support

### Installation

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, sops-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        sops-nix.nixosModules.sops
        ./configuration.nix
      ];
    };
  };
}
```

### Setup

#### 1. Generate age key from SSH key

```bash
# Convert your SSH key to age
nix-shell -p ssh-to-age --run 'ssh-to-age < ~/.ssh/id_ed25519.pub'
# Output: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# For host key (use this for the machine)
nix-shell -p ssh-to-age --run 'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
```

#### 2. Create .sops.yaml

```yaml
# .sops.yaml in repo root
keys:
  # Personal key (your SSH key converted to age)
  - &admin age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

  # Host keys (each machine that needs to decrypt)
  - &server1 age1xyz...
  - &laptop age1abc...

creation_rules:
  # Secrets for all hosts
  - path_regex: secrets/common\.yaml$
    key_groups:
      - age:
        - *admin
        - *server1
        - *laptop

  # Server-specific secrets
  - path_regex: secrets/server1\.yaml$
    key_groups:
      - age:
        - *admin
        - *server1
```

#### 3. Create encrypted secrets file

```bash
# Create secrets directory
mkdir -p secrets

# Create/edit secrets (opens $EDITOR)
nix-shell -p sops --run 'sops secrets/common.yaml'
```

```yaml
# secrets/common.yaml (this is what you edit in sops)
db_password: supersecret123
api_token: tok_xxxxxxxxxxxxx
smtp_password: mailpass456
```

#### 4. Use secrets in NixOS config

```nix
# configuration.nix
{ config, ... }:

{
  sops = {
    # Default sops file for this host
    defaultSopsFile = ./secrets/common.yaml;

    # Use host SSH key for decryption
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # Define secrets
    secrets = {
      db_password = {
        owner = "postgres";
        group = "postgres";
        mode = "0400";
      };

      api_token = {
        # Defaults: owner=root, group=root, mode=0400
      };

      smtp_password = {
        owner = "postfix";
      };
    };
  };

  # Use secrets in services
  services.postgresql = {
    enable = true;
    # Secret available at runtime
    # config.sops.secrets.db_password.path = "/run/secrets/db_password"
  };

  # For services that need password file
  services.myservice = {
    enable = true;
    passwordFile = config.sops.secrets.db_password.path;
  };
}
```

### Templates (Embedding Secrets in Files)

For config files that need secrets embedded:

```nix
{ config, ... }:

{
  sops.secrets.db_password = {};
  sops.secrets.db_username = {};

  sops.templates."myapp.conf" = {
    content = ''
      [database]
      host = localhost
      username = ${config.sops.placeholder.db_username}
      password = ${config.sops.placeholder.db_password}

      [server]
      port = 8080
    '';

    owner = "myapp";
    path = "/etc/myapp/config.conf";
  };

  # Service can now read /etc/myapp/config.conf
}
```

### Per-Host Secrets

```nix
{ config, ... }:

{
  sops = {
    defaultSopsFile = ./secrets/${config.networking.hostName}.yaml;

    secrets = {
      host_specific_key = {};
    };
  };
}
```

---

## agenix

### Why agenix?

- Simpler than sops-nix
- Uses only age encryption (via SSH keys)
- Lightweight, minimal dependencies

### Installation

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, agenix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        agenix.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### Setup

#### 1. Create secrets.nix

```nix
# secrets/secrets.nix
let
  # User SSH public keys
  user1 = "ssh-ed25519 AAAA... user@host";

  # Host SSH public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  server1 = "ssh-ed25519 AAAA... root@server1";
  laptop = "ssh-ed25519 AAAA... root@laptop";

  # Groups
  allUsers = [ user1 ];
  allHosts = [ server1 laptop ];
in {
  # Each secret and who can decrypt it
  "db_password.age".publicKeys = allUsers ++ allHosts;
  "api_token.age".publicKeys = allUsers ++ [ server1 ];
  "laptop_secret.age".publicKeys = allUsers ++ [ laptop ];
}
```

#### 2. Create encrypted secrets

```bash
cd secrets

# Edit/create a secret (uses secrets.nix to determine keys)
nix run github:ryantm/agenix -- -e db_password.age

# Re-key all secrets after adding new keys
nix run github:ryantm/agenix -- -r
```

#### 3. Use in NixOS config

```nix
# configuration.nix
{ config, ... }:

{
  age.secrets = {
    db_password = {
      file = ./secrets/db_password.age;
      owner = "postgres";
      group = "postgres";
      mode = "0400";
    };

    api_token.file = ./secrets/api_token.age;
  };

  # Use the secret
  services.myservice = {
    passwordFile = config.age.secrets.db_password.path;
    # path is /run/agenix/db_password
  };
}
```

---

## Comparison

| Feature | sops-nix | agenix |
|---------|----------|--------|
| Encryption | age, GPG, AWS/GCP/Azure KMS | age only |
| Key source | SSH keys, age keys, cloud | SSH keys, age keys |
| Templates | Yes | No |
| Binary secrets | Yes | Yes |
| Complexity | Medium | Low |
| Cloud integration | Yes | No |
| Active development | Very active | Active |

### When to Use Which

**Use sops-nix if:**
- You need templates (secrets embedded in config files)
- You use cloud KMS (AWS, GCP, Azure)
- You want GPG support
- You have complex multi-environment setups

**Use agenix if:**
- You want simplicity
- You only need age/SSH key encryption
- Your secrets are mostly file-based

---

## Best Practices

### 1. Never Commit Decrypted Secrets

```bash
# .gitignore
*.decrypted
*.plaintext
secrets/*.txt
```

### 2. Use Host Keys for Machine Identity

```nix
# Each machine decrypts with its own SSH host key
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
```

### 3. Separate Secrets by Host/Environment

```
secrets/
├── common.yaml           # Shared secrets
├── production.yaml       # Production only
├── development.yaml      # Dev only
├── server1.yaml          # Host-specific
└── laptop.yaml           # Host-specific
```

### 4. Restrict Secret Permissions

```nix
sops.secrets.sensitive_key = {
  owner = "myservice";
  group = "myservice";
  mode = "0400";  # Read-only by owner
};
```

### 5. Use `restartTriggers` for Secret Changes

```nix
systemd.services.myservice = {
  restartTriggers = [
    config.sops.secrets.api_token.path
  ];
};
```

### 6. Document Required Secrets

```nix
# In your module
{ config, lib, ... }:

{
  # Document what secrets are needed
  # Required secrets:
  # - sops.secrets.myservice_password
  # - sops.secrets.myservice_api_key

  assertions = [{
    assertion = config.sops.secrets ? myservice_password;
    message = "myservice requires sops.secrets.myservice_password to be defined";
  }];
}
```

---

## Common Patterns

### Database Password

```nix
{ config, ... }:

{
  sops.secrets.postgres_password = {
    owner = "postgres";
    group = "postgres";
  };

  services.postgresql = {
    enable = true;
    authentication = ''
      local all all peer
      host all all 127.0.0.1/32 scram-sha-256
    '';
  };

  # Set password via script
  systemd.services.postgresql.postStart = ''
    $PSQL -c "ALTER USER postgres PASSWORD '$(cat ${config.sops.secrets.postgres_password.path})'"
  '';
}
```

### Nginx SSL Certificates

```nix
{ config, ... }:

{
  sops.secrets = {
    "ssl/example.com.key" = {
      owner = "nginx";
      path = "/var/lib/secrets/ssl/example.com.key";
    };
    "ssl/example.com.crt" = {
      owner = "nginx";
      path = "/var/lib/secrets/ssl/example.com.crt";
    };
  };

  services.nginx.virtualHosts."example.com" = {
    enableSSL = true;
    sslCertificate = config.sops.secrets."ssl/example.com.crt".path;
    sslCertificateKey = config.sops.secrets."ssl/example.com.key".path;
  };
}
```

### Environment Variables

```nix
{ config, ... }:

{
  sops.secrets.api_key = {};

  systemd.services.myapp = {
    serviceConfig = {
      EnvironmentFile = config.sops.secrets.api_key.path;
    };
  };
}

# Or with templates
{
  sops.secrets.api_key = {};
  sops.secrets.db_url = {};

  sops.templates."myapp.env" = {
    content = ''
      API_KEY=${config.sops.placeholder.api_key}
      DATABASE_URL=${config.sops.placeholder.db_url}
    '';
  };

  systemd.services.myapp = {
    serviceConfig = {
      EnvironmentFile = config.sops.templates."myapp.env".path;
    };
  };
}
```

---

## Troubleshooting

### Secret Not Decrypting

```bash
# Check if host key is in .sops.yaml
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Verify sops can decrypt
sops -d secrets/common.yaml

# Check age key path
ls -la /etc/ssh/ssh_host_ed25519_key
```

### Permission Denied

```bash
# Check secret permissions
ls -la /run/secrets/

# Verify service user
ps aux | grep myservice
```

### Secret Not Available at Boot

Secrets are decrypted during activation, which happens after initrd but before most services. For initrd secrets, additional configuration is needed.

---

## Anti-Patterns

### DON'T: Store secrets in environment

```nix
# BAD - visible in /proc
environment.variables.API_KEY = "secret";
```

### DON'T: Use git-crypt for NixOS secrets

```nix
# BAD - secrets end up in /nix/store unencrypted
someService.password = builtins.readFile ./git-crypt-secret;
```

### DON'T: Hardcode paths

```nix
# BAD
passwordFile = "/run/secrets/my_password";

# GOOD
passwordFile = config.sops.secrets.my_password.path;
```

---

## Confidence
0.95 - Patterns from official documentation and production usage.

## Sources
- [sops-nix](https://github.com/Mic92/sops-nix)
- [agenix](https://github.com/ryantm/agenix)
- [NixOS Wiki - Secret Management](https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes)
- [NixOS Discourse - Handling Secrets](https://discourse.nixos.org/t/handling-secrets-in-nixos-an-overview-git-crypt-agenix-sops-nix-and-when-to-use-them/35462)
