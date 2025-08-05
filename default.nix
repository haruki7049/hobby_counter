{
  lib,
  stdenv,
  rustPlatform,

  pkg-config,
  dioxus-cli,

  gtk3,
  cairo,
  pango,
  libsoup_3,
  webkitgtk_4_1,
  xdotool,
}:

rustPlatform.buildRustPackage {
  name = "hobby_counter";
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [
    pkg-config
    dioxus-cli
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    gtk3
    cairo
    pango
    libsoup_3
    webkitgtk_4_1
    xdotool
  ];

  buildPhase = ''
    dx build --release --platform=desktop
  '';

  installPhase =
    if stdenv.isLinux then
      ''
        mkdir -p $out/share/hobby_counter
        cp -r target/dx/hobby_counter/release/linux/app/* $out/share/hobby_counter

        mkdir -p $out/bin
        ln -s $out/share/hobby_counter/hobby_counter $out/bin/hobby_counter
      ''
    else
      ''
        mkdir -p $out/Applications
        cp -r target/dx/hobby_counter/release/macos/Hoge.app $out/Applications
      '';

  meta = {
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
  };
}
