#!/usr/bin/env bash
set -euo pipefail

# Ensure bundler is present (Nix gives us bundler, but this is harmless)
gem install --no-document bundler || true

# Install deps if a Gemfile exists
if [ -f Gemfile ]; then
  bundle install
fi

# Generate a simple binstub for convenience (optional)
if [ -f Gemfile ]; then
  bundle binstubs --all || true
fi
