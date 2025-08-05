{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    crane.url = "github:ipetkov/crane";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          pkgs,
          lib,
          system,
          ...
        }:
        let
          rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rust;
          overlays = [ inputs.rust-overlay.overlays.default ];

          src = lib.cleanSource ./.;
          nativeBuildInputs = [
            # Dioxus CLI
            pkgs.dioxus-cli

            # Dioxus web dependencies
            pkgs.wasm-bindgen-cli_0_2_100
            pkgs.lld

            # Rust Compiler
            pkgs.cargo
            pkgs.rustc
            pkgs.pkg-config

            # LSP
            pkgs.nil
          ];
          buildInputs = lib.optionals pkgs.stdenv.isLinux [
            pkgs.gtk3
            pkgs.cairo
            pkgs.pango
            pkgs.libsoup_3
            pkgs.webkitgtk_4_1
            pkgs.xdotool
          ];

          cargoArtifacts = craneLib.buildDepsOnly {
            inherit src buildInputs nativeBuildInputs;
          };
          counter = craneLib.buildPackage {
            inherit
              src
              cargoArtifacts
              buildInputs
              nativeBuildInputs
              ;
            strictDeps = true;
            doCheck = true;

            installPhaseCommand =
              if pkgs.stdenv.isLinux then
                ''
                  # Build
                  dx build --release --platform=desktop

                  # Install
                  mkdir -p $out/share/hobby_counter
                  cp -r target/dx/hobby_counter/release/linux/app/* $out/share/hobby_counter

                  # Create a symlink
                  mkdir -p $out/bin
                  ln -s $out/share/hobby_counter/hobby_counter $out/bin/hobby_counter
                ''
              else
                ''
                  # Build
                  dx build --release --platform=desktop

                  # Install
                  mkdir -p $out/Applications
                  cp -r target/dx/hobby_counter/release/macos/HobbyCounter.app $out/Applications
                '';

            meta = {
              licenses = [ lib.licenses.mit ];
            };
          };
          cargo-clippy = craneLib.cargoClippy {
            inherit
              src
              cargoArtifacts
              buildInputs
              nativeBuildInputs
              ;

            cargoClippyExtraArgs = "--verbose -- --deny warnings";
          };
          cargo-doc = craneLib.cargoDoc {
            inherit
              src
              cargoArtifacts
              buildInputs
              nativeBuildInputs
              ;
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system overlays;
          };

          treefmt = {
            projectRootFile = "flake.nix";

            # Nix
            programs.nixfmt.enable = true;

            # Rust
            programs.rustfmt.enable = true;

            # TOML
            programs.taplo.enable = true;

            # GitHub Actions
            programs.actionlint.enable = true;

            # Markdown
            programs.mdformat.enable = true;

            # ShellScript
            programs.shellcheck.enable = true;
            programs.shfmt.enable = true;
          };

          packages = {
            inherit counter;
            default = counter;
            doc = cargo-doc;
          };

          checks = {
            inherit cargo-clippy;
          };

          devShells.default = pkgs.mkShell {
            inherit buildInputs nativeBuildInputs;

            shellHook = ''
              export PS1="\n[nix-shell:\w]$ "
            '';
          };
        };
    };
}
