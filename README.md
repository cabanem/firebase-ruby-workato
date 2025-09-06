# GitHub Codespaces to Google Firebase Studio (IDX) Migration

This repository contains an automated migration script to convert GitHub Codespaces `devcontainer.json` configurations to Google Firebase Studio (IDX) format.

## 🚀 Quick Start

Run this single command in your IDX terminal to set up your complete Ruby development environment:

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_REPO/main/setup-idx.sh | bash
```

Or copy and run the complete setup script directly:

```bash
bash -c '
mkdir -p .idx .vscode .bundle

# Create dev.nix
cat > .idx/dev.nix << '\''DEVNIX'\''
{ pkgs, ... }: {
  packages = [
    pkgs.ruby_3_3
    pkgs.bundler
    pkgs.nodejs_20
    pkgs.git
    pkgs.gh
    pkgs.zsh
    pkgs.oh-my-zsh
    pkgs.gcc
    pkgs.gnumake
    pkgs.icu
    pkgs.file
    pkgs.cmake
    pkgs.pkg-config
    pkgs.openssl
    pkgs.rubyPackages_3_3.solargraph
    pkgs.rubocop
  ];

  env = {
    RAILS_ENV = "development";
    BUNDLE_JOBS = "4";
    BUNDLE_RETRY = "3";
    BUNDLE_WITHOUT = "production";
    BUNDLE_PATH = "vendor/bundle";
  };

  idx = {
    workspace = {
      onCreate = {
        bundle-install = {
          runIn = "terminal";
          command = "gem install bundler && bundle config set --local path vendor/bundle && if [ -f Gemfile ]; then bundle install; fi";
        };
      };
      onStart = {
        start-server = {
          runIn = "terminal";
          command = "if [ -f bin/dev ]; then bin/dev; elif [ -f config.ru ]; then bundle exec rails server -b 0.0.0.0; fi";
        };
      };
    };
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["bundle" "exec" "rails" "server" "-b" "0.0.0.0" "-p" "$PORT"];
          manager = "web";
          env = { PORT = "3000"; };
        };
      };
    };
    extensions = [
      "anthropic.claude-code"
      "github.copilot"
      "shopify.ruby-lsp"
      "kaiwood.endwise"
      "castwide.solargraph"
    ];
  };
}
DEVNIX

# Create idx.json
cat > .idx/idx.json << '\''IDXJSON'\''
{
  "name": "Ruby Development Environment",
  "icon": "https://raw.githubusercontent.com/devicons/devicon/master/icons/ruby/ruby-original.svg",
  "previews": [
    {"port": 3000, "label": "Rails App"},
    {"port": 3001, "label": "Alt Server"},
    {"port": 4567, "label": "Sinatra"},
    {"port": 9292, "label": "Rack"}
  ]
}
IDXJSON

# Create and make executable setup.sh
cat > .idx/setup.sh << '\''SETUP'\'' && chmod +x .idx/setup.sh
#!/bin/bash
if [ -x "$(command -v zsh)" ]; then
  echo "Setting up Zsh with Oh My Zsh..."
  [ ! -f ~/.zshrc ] && cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
  grep -q "RAILS_ENV" ~/.zshrc || echo '\''
export HISTFILE=~/.zsh_history
export RAILS_ENV=development
export BUNDLE_PATH=vendor/bundle
export EDITOR=code
alias be="bundle exec"
alias bi="bundle install"
alias rs="bundle exec rails server"
alias rc="bundle exec rails console"'\'' >> ~/.zshrc
fi
git config --global --add safe.directory /home/user/workspace
SETUP

# Create VS Code settings
cat > .vscode/settings.json << '\''VSCODE'\''
{
  "terminal.integrated.defaultProfile.linux": "zsh",
  "editor.formatOnSave": true,
  "ruby.format": "rubocop",
  "ruby.lint": {"rubocop": true},
  "files.watcherExclude": {
    "**/vendor/bundle/**": true,
    "**/node_modules/**": true,
    "**/tmp/**": true,
    "**/log/**": true,
    "**/.bundle/**": true
  },
  "ruby.lsp.enabled": true,
  "ruby.lsp.formatter": "auto"
}
VSCODE

# Create Bundle config
cat > .bundle/config << '\''BUNDLE'\''
---
BUNDLE_PATH: "vendor/bundle"
BUNDLE_JOBS: "4"
BUNDLE_RETRY: "3"
BUNDLE_WITHOUT: "production"
BUNDLE

echo "✅ All IDX configuration files created successfully!"
echo "📝 Files created:"
echo "   - .idx/dev.nix"
echo "   - .idx/idx.json"
echo "   - .idx/setup.sh (executable)"
echo "   - .vscode/settings.json"
echo "   - .bundle/config"
echo ""
echo "🚀 Next steps:"
echo "   1. Refresh your IDX workspace to apply the Nix configuration"
echo "   2. Run: ./.idx/setup.sh"
echo "   3. Run: bundle install"
'
```

## 📋 What This Script Does

The automated migration script creates a complete IDX development environment equivalent to your GitHub Codespaces setup by:

1. **Creating IDX Configuration Files**
   - `.idx/dev.nix` - Nix package definitions and environment setup
   - `.idx/idx.json` - Workspace metadata and preview configurations
   - `.idx/setup.sh` - Shell environment initialization script

2. **Setting Up Development Tools**
   - Ruby 3.3 with Bundler
   - Node.js 20
   - Git and GitHub CLI
   - Zsh with Oh My Zsh
   - Build dependencies (gcc, make, cmake, etc.)
   - Ruby development tools (Solargraph, RuboCop)

3. **Configuring VS Code**
   - `.vscode/settings.json` - Editor preferences and Ruby LSP settings
   - Extension recommendations
   - File watcher exclusions for better performance

4. **Bundle Configuration**
   - `.bundle/config` - Bundler settings for consistent gem management
   - Local vendor/bundle path configuration
   - Parallel job settings for faster installations

## 🔄 Migration Mapping

| GitHub Codespaces | Google Firebase Studio (IDX) | Notes |
|-------------------|------------------------------|-------|
| `devcontainer.json` | `.idx/dev.nix` | Nix-based configuration |
| Docker image | Nix packages | Declarative package management |
| Volume mounts | Persistent workspace | Entire workspace persists |
| `forwardPorts` | Preview configurations | Auto-detected ports |
| `postCreateCommand` | `workspace.onCreate` | Lifecycle hooks |
| `postAttachCommand` | `workspace.onStart` | Startup commands |
| apt packages | Nix packages | Most packages have equivalents |
| VS Code customizations | `.vscode/settings.json` + extensions | Direct file configuration |

## 🛠️ Post-Installation Steps

After running the automated script:

1. **Refresh your IDX workspace** to apply the Nix configuration
2. **Initialize your shell environment**:
   ```bash
   ./.idx/setup.sh
   ```
3. **Install Ruby dependencies**:
   ```bash
   bundle install
   ```
4. **Start your application**:
   ```bash
   bundle exec rails server  # or your specific start command
   ```

## 📦 Environment Details

### Installed Packages
- **Ruby**: 3.3 with Bundler
- **Node.js**: 20.x
- **Shell**: Zsh with Oh My Zsh
- **Version Control**: Git, GitHub CLI
- **Build Tools**: GCC, Make, CMake, pkg-config
- **Libraries**: OpenSSL, ICU, libmagic
- **Ruby Tools**: Solargraph, RuboCop

### Environment Variables
```bash
RAILS_ENV=development
BUNDLE_PATH=vendor/bundle
BUNDLE_JOBS=4
BUNDLE_RETRY=3
BUNDLE_WITHOUT=production
```

### Shell Aliases
```bash
be  # bundle exec
bi  # bundle install
rs  # bundle exec rails server
rc  # bundle exec rails console
```

### Available Ports
- 3000 - Rails App (default)
- 3001 - Alternative Server
- 4567 - Sinatra
- 9292 - Rack

## 🔧 Customization

To modify the configuration for your specific needs:

### Adding Packages
Edit `.idx/dev.nix` and add packages to the `packages` array:
```nix
packages = [
  # ... existing packages ...
  pkgs.postgresql_15  # Example: Add PostgreSQL
];
```

### Changing Ruby Version
Replace `pkgs.ruby_3_3` with your desired version:
```nix
packages = [
  pkgs.ruby_3_2  # Use Ruby 3.2 instead
  # ...
];
```

### Adding Environment Variables
Edit the `env` section in `.idx/dev.nix`:
```nix
env = {
  # ... existing variables ...
  MY_CUSTOM_VAR = "value";
};
```

## 🐛 Troubleshooting

### Workspace doesn't recognize changes
- Refresh the workspace or restart IDX
- Ensure `.idx/dev.nix` has valid Nix syntax

### Bundle install fails
```bash
# Clear bundle cache and retry
rm -rf vendor/bundle
bundle install --jobs 4 --retry 3
```

### Gems with native extensions fail
```bash
# Ensure all build dependencies are installed
nix-shell -p gcc gnumake
bundle install
```

### Port not accessible
- Check the preview configuration in `.idx/idx.json`
- Ensure your application binds to `0.0.0.0` not `localhost`

## 📚 Additional Resources

- [Google Firebase Studio (IDX) Documentation](https://developers.google.com/idx)
- [Nix Package Search](https://search.nixos.org/packages)
- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [Bundler Documentation](https://bundler.io/docs.html)

## 📄 License

This migration script is provided as-is for development convenience. Adapt it to your specific needs.

## 🤝 Contributing

To improve this migration script:

1. Test with your specific devcontainer configuration
2. Document any package mapping discoveries
3. Share additional lifecycle hooks or optimizations
4. Report issues with specific gem or package installations

---

**Pro Tip**: Save the setup script as `setup-idx.sh` in your repository root for easy team onboarding:

```bash
# Team members can then simply run:
chmod +x setup-idx.sh && ./setup-idx.sh
```

This ensures consistent development environments across your team with a single command! 🚀