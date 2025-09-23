{ pkgs, ... }:
  packages = [
    pkgs.ruby_3_2
    pkgs.bundler

    # Native build toolchain for common Ruby gems
    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.openssl
    pkgs.zlib
    pkgs.libyaml
    pkgs.readline

    # ICU enables charlock_holmes (optional dep some stacks use)
    pkgs.icu

    # Optional XML deps—keep if you actually need Nokogiri’s system libs
    pkgs.libxml2
    pkgs.libxslt

    pkgs.git
    pkgs.bash
  ];

  # Env vars live here and are available to shells and previews.
  env = {
    BUNDLE_PATH = "vendor/bundle";
    BUNDLE_JOBS = "4";
    ICU_DIR = "${pkgs.icu.dev}";
    PKG_CONFIG_PATH = "${pkgs.icu.dev}/lib/pkgconfig";
    # If you use charlock_holmes, this helps bundler find ICU:
    BUNDLE_BUILD__CHARLOCK_HOLMES = "--with-icu-dir=${pkgs.icu.dev}";
  };

  # Runs only on first workspace creation/open.
  idx.workspace.onCreate = {
    setup = "bash .idx/setup.sh";
    default.openFiles = [ "Gemfile" ];
  };

  # Runs on every workspace open; cheap, idempotent checks belong here.
  idx.workspace.onStart = {
    verify = "bash .idx/verify.sh";
  };
}
