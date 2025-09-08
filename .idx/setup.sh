#!/bin/bash
# .idx/setup.sh - Workato SDK Development Setup

echo "================================================"
echo "     Workato Connector SDK Setup"
echo "================================================"

# Basic environment setup (works with bash or zsh)
setup_environment() {
    local shell_rc="$HOME/.bashrc"
    
    # Detect shell and use appropriate rc file
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    fi
    
    # Check if already configured
    if grep -q "WORKATO_SDK_SETUP" "$shell_rc" 2>/dev/null; then
        echo "✓ Environment already configured"
        return
    fi
    
    # Add environment variables and aliases
    cat >> "$shell_rc" << 'EOF'

# WORKATO_SDK_SETUP - Workato Connector Development
export BUNDLE_PATH="vendor/bundle"
export WORKATO_ENV="development"

# Workato SDK aliases
alias wt="workato exec test"
alias wa="workato exec action"
alias wtr="workato exec trigger"
alias wc="workato console"

# Bundle aliases
alias be="bundle exec"
alias bi="bundle install"

# WORKATO_SDK_SETUP_END
EOF
    
    echo "✓ Environment variables and aliases added to $shell_rc"
}

# Create project structure
setup_project() {
    # Create necessary directories
    mkdir -p spec input fixtures
    
    # Create settings template if it doesn't exist
    if [ ! -f settings.yaml.example ]; then
        cat > settings.yaml.example << 'EOF'
# Example settings file for testing
# Copy to settings.yaml and add your credentials
api_key: your_api_key_here
subdomain: your_subdomain
environment: sandbox
EOF
        echo "✓ Created settings.yaml.example"
    fi
    
    # Create gitignore if needed
    if [ ! -f .gitignore ]; then
        cat > .gitignore << 'EOF'
# Credentials
settings.yaml
settings.yml
.env

# Bundle
vendor/bundle/
.bundle/

# Testing
spec/fixtures/vcr_cassettes/
tmp/
EOF
        echo "✓ Created .gitignore"
    fi
}

# Main setup
main() {
    echo ""
    echo "Starting setup..."
    echo ""
    
    # Setup environment
    setup_environment
    
    # Setup project structure
    setup_project
    
    # Configure git (only for current directory)
    git config --global --add safe.directory "$(pwd)"
    echo "✓ Git safe directory configured"
    
    # Bundle configuration
    bundle config set --local path 'vendor/bundle' 2>/dev/null
    echo "✓ Bundle path configured"
    
    echo ""
    echo "================================================"
    echo "Setup complete! Next steps:"
    echo ""
    echo "1. Copy settings.yaml.example to settings.yaml"
    echo "2. Add your credentials to settings.yaml"
    echo "3. Run: bundle install"
    echo "4. Run: workato exec test settings.yaml"
    echo ""
    echo "Quick commands:"
    echo "  wt settings.yaml         - Test connection"
    echo "  wa <action> input.json   - Run action"
    echo "  wc                       - Open console"
    echo "================================================"
}

# Run main function
main