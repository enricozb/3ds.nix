{ stdenv, picasso-src, autoreconfHook }:

stdenv.mkDerivation {
  pname = "picasso";
  version = picasso-src.rev;

  src = picasso-src;

  nativeBuildInputs = [ autoreconfHook ];

  preAutoreconf = ''
    sed -i 's/AM_INIT_AUTOMAKE(\[subdir-objects\])/AM_INIT_AUTOMAKE([foreign subdir-objects])/' configure.ac
  '';

  meta = {
    description = "PICA200 GPU shader assembler for 3DS development";
    homepage = "https://github.com/devkitPro/picasso";
    platforms = [ "x86_64-linux" ];
  };
}
