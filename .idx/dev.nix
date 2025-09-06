# .idx/dev.nix
{ pkgs, ... }: {
  # Define which packages to install
  packages = [
    pkgs.ruby_3_3
    pkgs.bundler
    pkgs.nodejs_20
    pkgs.git
    pkgs.gh  # GitHub CLI
    pkgs.zsh
    pkgs.oh-my-zsh
    
    # Build dependencies
    pkgs.gcc
    pkgs.gnumake
    pkgs.icu
    pkgs.file  # for libmagic
    pkgs.cmake
    pkgs.pkg-config
    pkgs.openssl
    
    # Ruby development tools
    pkgs.rubyPackages_3_3.solargraph
    pkgs.rubocop
  ];

  # Environment variables
  env = {
    RAILS_ENV = "development";
    BUNDLE_JOBS = "4";
    BUNDLE_RETRY = "3";
    BUNDLE_WITHOUT = "production";
    BUNDLE_PATH = "vendor/bundle";
  };

  # IDX configuration
  idx = {
    # Define workspace lifecycle hooks
    workspace = {
      onCreate = {
        # Install Ruby dependencies
        bundle-install = {
          runIn = "terminal";
          command = ''
            gem install bundler
            bundle config set --local path "vendor/bundle"
            
            if [ -f Gemfile ]; then
              if [ ! -f Gemfile.lock ]; then
                echo "No Gemfile.lock found, generating it..."
                bundle install || (
                  echo "Bundle install failed, attempting to install known gems individually..."
                  gem install workato-connector-sdk charlock_holmes -v "~> 0.7.7" rubocop pry rspec
                  bundle lock --add-platform x86_64-linux || echo "Warning: Could not generate complete Gemfile.lock"
                )
              else
                echo "Gemfile.lock exists, running bundle install..."
                bundle install
              fi
            else
              echo "No Gemfile found, skipping bundle operations"
            fi
            
            echo "Setup complete!"
          '';
        };
      };
      
      onStart = {
        # Commands to run when workspace starts
        start-server = {
          runIn = "terminal";
          command = ''
            if [ -f bin/dev ]; then
              bin/dev
            elif [ -f config.ru ]; then
              bundle exec rails server -b 0.0.0.0
            fi
          '';
        };
      };
    };

    # Configure previews (equivalent to port forwarding)
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["bundle" "exec" "rails" "server" "-b" "0.0.0.0" "-p" "$PORT"];
          manager = "web";
          env = {
            PORT = "3000";
          };
        };
      };
    };

    # Extensions to install
    extensions = [
      "anthropic.claude-code"
      "github.copilot"
      "shopify.ruby-lsp"
      "kaiwood.endwise"
      "castwide.solargraph"
    ];
  };
}