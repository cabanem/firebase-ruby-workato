{ pkgs, ... }: {
  # Essential packages only
  packages = [
    # Ruby environment
    pkgs.ruby_3_3
    pkgs.bundler
    
    # Build essentials for native gems (required by Workato SDK dependencies)
    pkgs.gcc
    pkgs.gnumake
    pkgs.openssl
    pkgs.libxml2  # Often needed for XML parsing gems
    pkgs.libxslt  # XSLT support
    
    # Version control
    pkgs.git
    
    # Basic shell
    pkgs.bash
  ];

  env = {
    # Minimal environment variables
    BUNDLE_PATH = "vendor/bundle";
    BUNDLE_JOBS = "4";
  };

  idx = {
    workspace = {
      # Simple, explicit setup - no magic
      onCreate = {
        setup = {
          runIn = "terminal";
          command = ''
            echo "==================================="
            echo "Workato SDK Development Environment"
            echo "==================================="
            echo ""
            echo "Setup Instructions:"
            echo "1. Run: bundle init (if no Gemfile exists)"
            echo "2. Add to Gemfile: gem 'workato-connector-sdk'"
            echo "3. Run: bundle install"
            echo "4. Run: workato --help"
            echo ""
            echo "Your bundle path is: vendor/bundle"
          '';
        };
      };
    };
  };
}