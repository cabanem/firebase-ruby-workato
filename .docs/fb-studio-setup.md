# Setup Summary

Lean, **offline‑friendly** Firebase Studio (ex‑IDX) setup for the `workato-connector-sdk`. You get Ruby + native C deps, a repeatable **Bash** bootstrap, an **offline guard** that prevents accidental HTTP, and a **non‑connected** sample connector (pure Ruby text utilities).

---

## Contents

* **Image with Ruby** via `.idx/dev.nix` (Firebase Studio reads this to build the VM). ([Firebase][1])
* All **C build deps** needed for native gems (ICU, OpenSSL, pkg-config, gcc, make, libxml2/xslt, etc.). The SDK depends on native extensions like `charlock_holmes`. ([GitHub][2], [6])
* **Gem loadability** and CLI ready: `./bin/workato` via Bundler binstubs.
* **One‑command, repeatable** bootstrap on workspace creation (Bash).
* **Offline guard** to block network during dev/test; optional on‑start verification.
* **No zsh, no rubocop** (Bash only).

> Notes: Project IDX was rebranded as **Firebase Studio** and uses **`.idx/dev.nix`** for deterministic environments. The SDK supports Ruby 2.7–3.1+; we install Ruby 3.1.x. ([Project IDX][3], [RubyGems][4])

---

## Files to add to your repo

### 1) `.idx/dev.nix`

Defines the environment Firebase Studio boots with. Adds an **onCreate** bootstrap and an **onStart** offline verification run.

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

  # Optional: prove the SDK loads and our offline connector runs at startup
  idx.workspace.onStart = {
    verify_offline = ''
      export WORKATO_OFFLINE=1
      export RUBYOPT="-r ./scripts/offline_guard.rb"
      ruby ./scripts/verify_sdk.rb || true
    '';
  };
}
```

**Why this works:** Firebase Studio treats `.idx/dev.nix` as the source of truth for packages, env vars, and tasks. You don’t pick a Docker base; you declare what you need. ([Firebase][1], [5])

---

### 2) `scripts/setup.sh`

Idempotent Bash bootstrap; installs Bundler, your gems, and **binstubs** for the SDK (and RSpec).

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

gem "workato-connector-sdk", "~> 1.3"

group :test do
  gem "rspec",   "~> 3.13"
  gem "webmock", "~> 3.18"
  gem "vcr",     "~> 6.2"
end
GEMFILE
fi

# Pin vendor path; keep tidy
bundle config set path "${BUNDLE_PATH}"
bundle config set clean true

# If ICU path is set by dev.nix, Bundler will pass it to charlock_holmes
bundle install --retry 2

# Binstubs for convenience
bundle binstubs workato-connector-sdk --path=bin
bundle binstubs rspec-core --path=bin

# Smoke test: verify the gem loads and the CLI responds
ruby -e 'require "workato-connector-sdk"; puts "SDK loaded: #{Workato::Connector::Sdk::VERSION}"' || {
  echo "ERROR: Could not load workato-connector-sdk"; exit 1;
}

./bin/workato --help >/dev/null
echo "==> Workato SDK installed and CLI available at ./bin/workato"
```

Make it executable:

```bash
chmod +x scripts/setup.sh
```

---

### 3) `scripts/offline_guard.rb`

Blocks network usage when `WORKATO_OFFLINE=1`. This catches common stacks that use `net/http` (e.g., `rest-client`).

```ruby
# blocks net/http (and best-effort EventMachine HTTP) if WORKATO_OFFLINE=1
return unless ENV['WORKATO_OFFLINE'] == '1'

require 'net/http'
module Net
  class HTTP
    alias __orig_request request
    def request(*)
      raise 'Network disabled by WORKATO_OFFLINE=1'
    end
  end
end

begin
  require 'em-http-request'
  module EventMachine
    class HttpRequest
      %i[head get post put delete].each do |m|
        define_method(m) { |_ *| raise 'Network disabled by WORKATO_OFFLINE=1' }
      end
    end
  end
rescue LoadError
end
```

---

### 4) `connector.rb` (root) — **Non‑connected** sample

Settings‑only connection. No `authorization`, no `base_uri`. Pure Ruby text utilities.

```ruby
# frozen_string_literal: true

{
  title: 'Text Utilities (offline)',

  # ------------------------------
  # CONNECTION: settings only
  # ------------------------------
  connection: {
    help: ->() { "Configure default settings for text processing. These can be overridden per action. Environment selection tunes verbosity and limits." },
    fields: [
      { name: "environment", label: "Environment", optional: false, control_type: "select",
        options: [["Development", "dev"], ["Staging", "staging"], ["Production", "prod"]] },
      { name: "chunk_size_default", label: "Default Chunk Size", type: :integer, control_type: "integer", default: 1000 },
      { name: "chunk_overlap_default", label: "Default Chunk Overlap", type: :integer, control_type: "integer", default: 100 },
      { name: "similarity_threshold", label: "Similarity Threshold", type: :number, control_type: "number", default: 0.7 }
    ]
    # NOTE: no authorization, no base_uri (we are offline)
  },

  # ------------------------------
  # TEST: local validation (no HTTP)
  # ------------------------------
  test: lambda do |connection|
    errs = []
    size = connection["chunk_size_default"].to_i
    over = connection["chunk_overlap_default"].to_i
    thr  = connection["similarity_threshold"].to_f
    errs << "chunk_size_default must be > 0" if size <= 0
    errs << "chunk_overlap_default must be >= 0 and < chunk_size_default" if over < 0 || over >= size
    errs << "similarity_threshold must be in [0,1]" unless (0.0..1.0).cover?(thr)
    error(errs.join("; ")) unless errs.empty?
    { environment: connection["environment"], status: "connected" }
  end,

  # ------------------------------
  # METHODS: pure-Ruby helpers
  # ------------------------------
  methods: {
    chunk_text: lambda do |text, size, overlap|
      tokens = text.to_s.split(/\s+/)
      step   = [1, size - overlap].max
      slices, i = [], 0
      while i < tokens.length
        segment = tokens[i, size] || []
        break if segment.empty?
        slices << segment.join(' ')
        i += step
      end
      slices
    end,
    cosine_similarity: lambda do |a, b|
      fa = Hash.new(0); a.to_s.downcase.scan(/\w+/).each { |w| fa[w] += 1 }
      fb = Hash.new(0); b.to_s.downcase.scan(/\w+/).each { |w| fb[w] += 1 }
      dot   = (fa.keys | fb.keys).sum { |w| fa[w] * fb[w] }
      mag_a = Math.sqrt(fa.values.sum { |v| v * v })
      mag_b = Math.sqrt(fb.values.sum { |v| v * v })
      mag_a.zero? || mag_b.zero? ? 0.0 : dot.to_f / (mag_a * mag_b)
    end
  },

  # ------------------------------
  # ACTIONS: offline processors
  # ------------------------------
  actions: {
    chunk_text: {
      title: 'Chunk text',
      input_fields: lambda do |_|
        [
          { name: 'text', type: :string, control_type: 'text-area', optional: false },
          { name: 'chunk_size', type: :integer, optional: true },
          { name: 'chunk_overlap', type: :integer, optional: true }
        ]
      end,
      execute: lambda do |connection, input|
        size = (input['chunk_size'] || connection['chunk_size_default']).to_i
        over = (input['chunk_overlap'] || connection['chunk_overlap_default']).to_i
        chunks = call(:chunk_text, input['text'], size, over)
        { 'count' => chunks.size, 'chunks' => chunks }
      end,
      output_fields: lambda do
        [{ name: 'count', type: :integer }, { name: 'chunks', type: :array, of: :string }]
      end
    },

    similarity: {
      title: 'Cosine similarity',
      input_fields: lambda do |_|
        [
          { name: 'a', type: :string, control_type: 'text-area', optional: false },
          { name: 'b', type: :string, control_type: 'text-area', optional: false },
          { name: 'threshold', type: :number, optional: true }
        ]
      end,
      execute: lambda do |connection, input|
        thr   = (input['threshold'] || connection['similarity_threshold']).to_f
        score = call(:cosine_similarity, input['a'], input['b'])
        { 'score' => score, 'match' => score >= thr }
      end,
      output_fields: lambda do
        [{ name: 'score', type: :number }, { name: 'match', type: :boolean }]
      end
    }
  }
}
```

---

### 5) `scripts/verify_sdk.rb`

Tiny “does it load and run offline?” script.

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true
require 'workato-connector-sdk'

settings  = Workato::Connector::Sdk::Settings.from_default_file
connector = Workato::Connector::Sdk::Connector.from_file('connector.rb', settings)

puts "SDK: #{Workato::Connector::Sdk::VERSION}"
connector.test(settings) # local validation

sample = "The quick brown fox jumps over the lazy dog. " * 10
out = connector.actions.chunk_text.execute(settings,
       { 'text' => sample, 'chunk_size' => 20, 'chunk_overlap' => 5 })
puts "Chunks: #{out['count']} (first: #{out['chunks'].first.inspect})"

sim = connector.actions.similarity.execute(settings,
       { 'a' => "alpha beta gamma", 'b' => "alpha beta", 'threshold' => 0.6 })
puts "Similarity: score=#{sim['score'].round(3)} match=#{sim['match']}"
```

---

### 6) `spec/spec_helper.rb`

Block the network in tests by default; VCR is configured but optional.

```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'rspec'
require 'webmock/rspec'
require 'vcr'
require 'workato-connector-sdk'

WebMock.disable_net_connect!(allow_localhost: true)

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :once }
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.order = :random
  Kernel.srand config.seed
end
```

---

### 7) `spec/connector_spec.rb`

Tests for the offline actions.

```ruby
# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'offline connector' do
  let(:settings)  { Workato::Connector::Sdk::Settings.from_default_file }
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('connector.rb', settings) }

  it 'validates connection settings' do
    expect { connector.test(settings) }.not_to raise_error
  end

  it 'chunks text' do
    res = connector.actions.chunk_text.execute(settings,
          { 'text' => 'a b c d e f g', 'chunk_size' => 3, 'chunk_overlap' => 1 })
    expect(res['count']).to be > 0
    expect(res['chunks'].first.split.size).to be_between(1, 3).inclusive
  end

  it 'computes similarity' do
    res = connector.actions.similarity.execute(settings,
          { 'a' => 'alpha beta', 'b' => 'alpha', 'threshold' => 0.1 })
    expect(res['score']).to be_between(0.0, 1.0)
    expect([true, false]).to include(res['match'])
  end
end
```

---

### 8) `settings.yaml`

Simple settings file; the SDK helpers pick this up automatically.

```yaml
environment: dev
chunk_size_default: 1000
chunk_overlap_default: 100
similarity_threshold: 0.7
```

---

## How to use it

1. **Commit** these files:

```
.idx/dev.nix
Gemfile
scripts/setup.sh
scripts/offline_guard.rb
scripts/verify_sdk.rb
connector.rb
spec/spec_helper.rb
spec/connector_spec.rb
settings.yaml
```

2. **Open in Firebase Studio** (or re‑open). The **onCreate** hook runs `scripts/setup.sh`; the **onStart** hook runs `verify_sdk.rb` with the offline guard. ([Firebase][1], [5])

3. **Verify manually (offline):**

```bash
# Prevent network calls during dev:
export WORKATO_OFFLINE=1
export RUBYOPT="-r ./scripts/offline_guard.rb"

./bin/workato --version
ruby -r workato-connector-sdk -e 'puts Workato::Connector::Sdk::VERSION'

# Connector self-check and actions:
./bin/workato exec test
./bin/workato exec actions.chunk_text.execute --input='{"text":"lorem ipsum dolor sit amet","chunk_size":4,"chunk_overlap":1}'
./bin/workato exec actions.similarity.execute --input='{"a":"alpha beta","b":"alpha"}'
```

4. **Run tests:**

```bash
bundle exec rspec
```

Network is blocked by WebMock; tests fail fast if anything tries HTTP.

5. **Temporarily allow network (e.g., when you add a connected action later):**

```bash
unset WORKATO_OFFLINE
unset RUBYOPT
# now connected actions can run; add VCR if you want recorded tests
```

---

## Why these choices

* **Nix + `.idx/dev.nix`** → deterministic VM on each open; zero snowflake drift. ([Firebase][1], [5])
* **ICU + pkg-config + libxml2/xslt** → native gem installs succeed (`charlock_holmes`, `nokogiri`). ([GitHub][6], [2])
* **Bundler binstubs** → `./bin/workato` and `./bin/rspec` are project‑scoped; no global gem pollution.
* **Offline guard** → prevents accidental HTTP in “non‑connected” workflows; reproducible tests.
* **Bash everywhere** → simple, portable; **no zsh**, **no rubocop**.

---

### References

* Firebase Studio uses `.idx/dev.nix` for workspace setup; see customization and reference pages. ([Firebase][1], [5])
* Project IDX → **Firebase Studio** rebrand info. ([Project IDX][3])
* Workato SDK gem docs & repo (CLI, structure, native deps). ([GitHub][2])
* Ruby version requirement on current gem releases. ([RubyGems][4])
* `charlock_holmes` native dependency context (ICU). ([GitHub][6])

[1]: https://firebase.google.com/docs/studio/customize-workspace "Customize your Firebase Studio workspace - Google"
[2]: https://github.com/workato/workato-connector-sdk "GitHub - workato/workato-connector-sdk"
[3]: https://idx.dev/ "Project IDX"
[4]: https://rubygems.org/gems/workato-connector-sdk/versions/1.3.16 "workato-connector-sdk 1.3.16"
[5]: https://firebase.google.com/docs/studio/devnix-reference "dev.nix Reference  |  Firebase Studio"
[6]: https://github.com/brianmario/charlock_holmes "brianmario/charlock_holmes: Character encoding ..."
[7]: https://open-vsx.org/extension/Shopify/ruby-lsp "Ruby LSP"
