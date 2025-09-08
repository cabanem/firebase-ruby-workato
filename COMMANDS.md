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
