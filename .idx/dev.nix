{ pkgs, ... }: {
  # Essential packages only
  packages = [
    # Ruby environment
    pkgs.ruby_3_3
    pkgs.bundler
    
    # Build essentials for native gems (required by Workato SDK dependenc{ pkgs }:
let
  # ruby = pkgs.ruby_3_2 # pick 3.3 or 3.2
  ruby = pkgs.ruby_3_3;
in {
  packages = [
    ruby
    pkgs.bundler

    # Build essentials for native gems
    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.openssl
    pkgs.zlib
    pkgs.libyaml
    pkgs.readline

    # XML stack (only if you truly need it)
    pkgs.libxml2
    pkgs.libxslt

    # ICU for charlock_holmes (and friends)
    pkgs.icu

    # Tools
    pkgs.git
    pkgs.bash
  ];

  shell = {
    init_hook = ''
      set -e

      # Keep gems inside the workspace; no host pollution.
      export GEM_HOME="$PWD/.gem"
      export GEM_PATH="$GEM_HOME"
      export BUNDLE_PATH="$PWD/vendor/bundle"
      export PATH="$GEM_HOME/bin:$PWD/bin:$PATH"

      # Help native gems find ICU if needed (charlock_holmes)
      export ICU_DIR="${pkgs.icu.dev}"
      export PKG_CONFIG_PATH="${pkgs.icu.dev}/lib/pkgconfig"

      # Bundler build flags for charlock_holmes (only used if present)
      export BUNDLE_BUILD__CHARLOCK_HOLMES="--with-icu-dir=${pkgs.icu.dev}"

      gem install --no-document bundler
      bundle config set path "$BUNDLE_PATH"
    '';
  };

  idx = {
    workspace = {
      onCreate = ''
        set -e
        if [ -f .idx/setup.sh ]; then
          bash .idx/setup.sh
        else
          # Fallback: install gems if Gemfile exists
          if [ -f Gemfile ]; then
            bundle install
          fi
        fi
      '';
    };
  };
}
ies)
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

    # Package deps
    ICU_DIR = "${pkgs.icu.dev}";
    PKG_CONFIG_PATH = "${pkgs.icu.dev}/lib/pkgconfig";
    
    # Additional build flags
    BUNDLE_BUILD__CHARLOCK_HOLMES = "--with-icu-dir=${pkgs.icu.dev}";
  
  };

  idx = {
    workspace = {
      # Simple, explicit setup - no magic
      onCreate = {
        setup - "bash .idx/setup.sh"
      };
    };
  };
}
