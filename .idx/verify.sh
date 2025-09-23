#!/usr/bin/env bash
set -euo pipefail

ruby -v || true
if [ -f Gemfile.lock ]; then
  bundle exec ruby -e 'require "rubygems"; if Gem.loaded_specs["workato-connector-sdk"]; puts "workato-connector-sdk " + Gem.loaded_specs["workato-connector-sdk"].version.to_s; else puts "workato-connector-sdk not installed"; end'
fi
