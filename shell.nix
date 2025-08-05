{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.dioxus-cli
    pkgs.cargo
    pkgs.rustc
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.gtk3
    pkgs.cairo
    pkgs.pango
    pkgs.libsoup_3
    pkgs.webkitgtk_4_1
    pkgs.xdotool
  ];
}
