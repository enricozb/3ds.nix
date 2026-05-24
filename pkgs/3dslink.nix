{
  stdenv,
  dslink-src,
  autoreconfHook,
  pkg-config,
  zlib,
}:

stdenv.mkDerivation {
  pname = "3dslink";
  version = dslink-src.rev;

  src = "${dslink-src}/host";

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];
  buildInputs = [ zlib ];

  meta = {
    description = "Tool to send 3DS homebrew over WiFi to the Homebrew Launcher";
    homepage = "https://github.com/devkitPro/3dslink";
    platforms = [ "x86_64-linux" ];
  };
}
