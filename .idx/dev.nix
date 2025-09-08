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