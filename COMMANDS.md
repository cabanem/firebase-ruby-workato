# Workato SDK Quick Reference

## Daily Commands

### Testing your connector
```bash
# Test connection
workato exec test settings.yaml

# Test an action
workato exec action get_record input.json settings.yaml

# Test a trigger
workato exec trigger new_record settings.yaml

# Open interactive console
workato console
```

### Development
```bash
# Install new gems
bundle add <gem_name>

# Run tests
bundle exec rspec

# Check for issues
workato check connector.rb
```
---

## Troubleshooting
### Manual Install Commands
```bash
# Check available ICU
ls /nix/store/*/icu*

# Find pkg-config
which pkg-config
pkg-config --list-all | grep icu

# Set environment manually
export PKG_CONFIG_PATH="/nix/store/*/icu*/lib/pkgconfig:$PKG_CONFIG_PATH"
export ICU_DIR="/nix/store/*/icu*"

# Try bundle with verbose output
bundle config set --local path 'vendor/bundle'
bundle install --verbose

# If still failing, install without native extensions
gem install workato-connector-sdk --ignore-dependencies
```

### Rebuild from Partial/Failed Build
```bash
# First try:
bundle config build.charlock_holmes --use-system-libraries
bundle install

# If that fails, try skipping charlock_holmes
gem install workato-connector-sdk --ignore-dependencies
gem install rest-client json jwt concurrent-ruby
```