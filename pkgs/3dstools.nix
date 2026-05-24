{ stdenv, tools-3ds-src, autoreconfHook }:

stdenv.mkDerivation {
  pname = "3dstools";
  version = tools-3ds-src.rev;

  src = tools-3ds-src;

  nativeBuildInputs = [ autoreconfHook ];

  meta = {
    description = "Tools for 3DS homebrew development (3dsxtool, smdhtool, bin2s, mkromfs3ds)";
    homepage = "https://github.com/devkitPro/3dstools";
    platforms = [ "x86_64-linux" ];
  };
}
