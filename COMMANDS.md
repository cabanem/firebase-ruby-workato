# Workato SDK Quick Reference

## Daily Commands

### Testing your connector
```bash
# Test connection
workato exec test settings.yaml

# Test specific action
workato exec action create_user input.json settings.yaml

# Test trigger
workato exec trigger new_user settings.yaml