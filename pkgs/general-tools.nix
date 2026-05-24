{
  stdenv,
  general-tools-src,
  autoreconfHook,
}:

stdenv.mkDerivation {
  pname = "general-tools";
  version = general-tools-src.rev;

  src = general-tools-src;

  nativeBuildInputs = [ autoreconfHook ];

  meta = {
    description = "General devkitPro tools (bin2s, padbin, raw2c, bmp2bin)";
    homepage = "https://github.com/devkitPro/general-tools";
    platforms = [ "x86_64-linux" ];
  };
}
