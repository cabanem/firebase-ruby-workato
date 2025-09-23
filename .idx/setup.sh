#!/usr/bin/env bash
set -euo pipefail

if [ -f Gemfile ]; then
  bundle install
fi

ruby -v
bundle exec ruby -e 'require "rubygems"; puts Gem.loaded_specs.key?("workato-connector-sdk") ? "workato-connector-sdk " + Gem.loaded_specs["workato-connector-sdk"].version.to_s : "workato-connector-sdk not in Gemfile"'
