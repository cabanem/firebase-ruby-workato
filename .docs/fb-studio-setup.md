# Setup Summary

Below you'll find a **drop‑in Firebase Studio (ex‑IDX)** setup that renders Ruby + the C toolchain required to install and use the `workato-connector-sdk` gem, with a repeatable **Bash** bootstrap.

---

## Contents

* **Image with Ruby** (in Firebase Studio this is expressed via `.idx/dev.nix`, which defines the VM environment) ([Firebase][1])
* All **C build deps** required for native gems like `charlock_holmes` (ICU, OpenSSL, pkg-config, gcc, make, etc.). The Workato SDK explicitly depends on `charlock_holmes`, which needs ICU headers/libs. ([GitHub][2])
* **Gem loadability** and CLI ready: `workato` available via Bundler binstubs.
* **One‑command, repeatable** bootstrap on workspace creation (Bash).
* **No zsh, no rubocop** (not installed; Bash is explicit).

> Notes for context: Project IDX was rebranded as **Firebase Studio** and uses **`.idx/dev.nix`** for deterministic dev environments. The SDK currently supports Ruby 2.7–3.1+; the gem requires ≥ 2.7.6. ([Project IDX][3])

---

## Files to add to your repo

### 1) `.idx/dev.nix`

Create this file to define the environment Firebase Studio boots with.

```nix
{ pkgs, lib, ... }: {
  # Modern, stable nixpkgs channel
  channel = "stable-24.11";

  # Toolchain + Ruby + native libs for typical Ruby native extensions
  packages = [
    pkgs.ruby_3_1
    pkgs.bashInteractive
    pkgs.git
    pkgs.gnumake
    pkgs.gcc
    pkgs.pkg-config

    # Headers/libs commonly needed by Ruby native gems
    pkgs.openssl
    pkgs.readline
    pkgs.zlib
    pkgs.libffi
    pkgs.libyaml
    pkgs.libxml2
    pkgs.libxslt

    # ICU for charlock_holmes (transitively needed by workato SDK)
    pkgs.icu

    # Misc useful
    pkgs.xz
    pkgs.cacert
    pkgs.curl
  ];

  env = {
    # Ensure TLS works for gem/bundle in Nix environments
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    # Keep it Bash (not zsh)
    SHELL = "${pkgs.bashInteractive}/bin/bash";

    # Vendor gems in the repo for reproducibility
    BUNDLE_PATH = "vendor/bundle";
    BUNDLE_JOBS = "4";

    # Help charlock_holmes find ICU during native build
    BUNDLE_BUILD__CHARLOCK_HOLMES = "--with-icu-dir=${pkgs.icu}";
  };

  # Editor quality-of-life (no RuboCop). Ruby LSP is light and fast.
  idx.extensions = [
    "Shopify.ruby-lsp"
  ];

  # Auto-bootstrap the gems when the workspace is first created
  idx.workspace.onCreate = {
    bootstrap = "bash ./scripts/setup.sh";
    default.openFiles = [ "README.md" ];
  };
}
```

**Why this works in Firebase Studio:** Studio uses `.idx/dev.nix` as the single source of truth for your environment (packages, env vars, tasks). You don’t pick a Docker base image; you declare exactly what you need here. ([Firebase][1])

---

### 2) `scripts/setup.sh`

Idempotent Bash bootstrap; installs Bundler, your gems, and a **binstubbed** `workato` CLI.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Run from repo root
cd "$(dirname "$0")/.."

echo "==> Ruby:"
ruby -v
echo "==> Gem:"
gem -v

# Keep installs inside the workspace for repeatability
export BUNDLE_PATH="${BUNDLE_PATH:-vendor/bundle}"
export BUNDLE_JOBS="${BUNDLE_JOBS:-4}"

# Make binstubs available for this repo
mkdir -p bin
export PATH="$(pwd)/bin:$PATH"

# Ensure Bundler is present & up to date (silent/no docs for speed)
gem install bundler -N 1>/dev/null

# If the Gemfile is missing, create a minimal one
if [ ! -f Gemfile ]; then
  cat > Gemfile <<'GEMFILE'
source "https://rubygems.org"

# Workato Connector SDK (CLI provides `workato` command)
gem "workato-connector-sdk", "~> 1.3"
GEMFILE
fi

# Pin vendor path; avoid any dev-only groups you don't want
bundle config set path "${BUNDLE_PATH}"
bundle config set clean true

# If ICU path is set by dev.nix, Bundler will pass it to charlock_holmes
bundle install --retry 2 --without "development test rubocop"

# Create a binstub for the CLI so we can just run ./bin/workato
bundle binstubs workato-connector-sdk --path=bin

# Smoke test: verify the gem loads and the CLI responds
ruby -e 'require "workato-connector-sdk"; puts "SDK loaded: #{Workato::Connector::Sdk::VERSION}"' || {
  echo "ERROR: Could not load workato-connector-sdk"; exit 1;
}

./bin/workato --help >/dev/null
echo "==> Workato SDK installed and CLI available at ./bin/workato"
```

> The SDK depends on `charlock_holmes` which compiles against **ICU**; we’ve included ICU and `pkg-config` in the environment and pass the ICU path to Bundler so the native build Just Works. ([GitHub][2])

Make sure it’s executable if you run it locally:

```bash
chmod +x scripts/setup.sh
```

---

### 3) Minimal `Gemfile` (if you want it checked in)

```ruby
source "https://rubygems.org"

# Workato SDK gem (Ruby >= 2.7.6)
gem "workato-connector-sdk", "~> 1.3"
```

> Recent gem versions require Ruby **≥ 2.7.6**; the Nix file above installs Ruby 3.1.x which is supported by Workato’s SDK docs. ([RubyGems][4])

---

## How to use it

1. **Commit** the three files above:

```
.idx/dev.nix
scripts/setup.sh
Gemfile
```

2. **Open in Firebase Studio** (or re-open an existing workspace). The **onCreate** hook will run `scripts/setup.sh` and cache the environment. ([Firebase][5])

3. **Verify**:

```bash
./bin/workato --version
ruby -r workato-connector-sdk -e 'puts Workato::Connector::Sdk::VERSION'
```

4. **Start a connector**:

```bash
./bin/workato new connectors/my_connector
EDITOR="nano" ./bin/workato edit settings.yaml.enc   # or your editor
./bin/workato exec test --connection="My Valid Connection"
```

(Those commands and the project structure come straight from Workato’s SDK docs & repo.) ([GitHub][2])

---

## Why these choices (quick rationale)

* **Nix + `.idx/dev.nix`** → deterministic VM image each time you open Studio; no hand-curating packages on the VM. ([Firebase][1])
* **ICU + pkg-config** → avoids the common native‑extension install failures with `charlock_holmes`. ([GitHub][6])
* **Bundler binstubs** → you get `./bin/workato` tied to the vendored gemset; no global gem pollution.
* **Bash everywhere** → keeps it simple and portable; **no zsh**.
* **No RuboCop** → you asked not to include it.

---

## Optional (nice-to-haves you can add later)

* **RSpec + VCR** for connector unit tests:

  ```ruby
  # Gemfile
  gem "rspec"; gem "vcr"; gem "webmock"
  ```

  This mirrors the structure and tooling Workato shows in its SDK docs. ([GitHub][2])

* **Studio extensions**: If you want richer inline Ruby tooling, keep **Ruby LSP** (already included). It’s the current, lightweight default for VS Code-compatible editors. ([open-vsx.org][7])

---

### References

* Firebase Studio uses `.idx/dev.nix` for workspace setup; doc updated Sept 9, 2025. ([Firebase][5])
* Project IDX → **Firebase Studio** rebrand confirmations. ([Project IDX][3])
* Workato SDK gem docs & repo (CLI, structure, and `charlock_holmes` dependency). ([GitHub][2])
* Ruby version requirement on current gem releases. ([RubyGems][4])

---

If you want me to also drop in a **sample connector skeleton** (pre-wired `connector.rb`, `spec/`, and a tiny `verify_sdk.rb`) I’ll paste that next so you can push and have Studio auto-boot into a runnable demo.

[1]: https://firebase.google.com/docs/studio/customize-workspace "Customize your Firebase Studio workspace - Google"
[2]: https://github.com/workato/workato-connector-sdk "GitHub - workato/workato-connector-sdk"
[3]: https://idx.dev/ "Project IDX"
[4]: https://rubygems.org/gems/workato-connector-sdk/versions/1.3.16 "workato-connector-sdk 1.3.16"
[5]: https://firebase.google.com/docs/studio/devnix-reference "dev.nix Reference  |  Firebase Studio"
[6]: https://github.com/brianmario/charlock_holmes "brianmario/charlock_holmes: Character encoding ..."
[7]: https://open-vsx.org/extension/Shopify/ruby-lsp "Ruby LSP"
