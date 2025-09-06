#!/bin/bash
# .idx/setup.sh

# Set zsh as default shell if available
if [ -x "$(command -v zsh)" ]; then
  echo "Setting up Zsh with Oh My Zsh..."
  
  # Create .zshrc if it doesn't exist
  if [ ! -f ~/.zshrc ]; then
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
  fi
  
  # Add custom configurations
  cat >> ~/.zshrc << 'EOF'
# Custom aliases and configurations
export HISTFILE=~/.zsh_history
export RAILS_ENV=development
export BUNDLE_PATH=vendor/bundle

# Set default editor
export EDITOR=code

# Ruby/Rails aliases
alias be="bundle exec"
alias bi="bundle install"
alias rs="bundle exec rails server"
alias rc="bundle exec rails console"
EOF
fi

# Ensure git safe directory
git config --global --add safe.directory /home/user/workspace