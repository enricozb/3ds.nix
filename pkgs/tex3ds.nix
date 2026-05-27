{
  stdenv,
  tex3ds-src,
  autoreconfHook,
  pkg-config,
  freetype,
  imagemagick,
}:

stdenv.mkDerivation {
  pname = "tex3ds";
  version = tex3ds-src.rev;

  src = tex3ds-src;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    freetype
    imagemagick
  ];

  # tex3ds's configure.ac forces pkg-config --static, which pulls in every
  # transitive ImageMagick dependency at link time (libraqm, libXext, etc.).
  # Drop the --static flag so we link only against the shared libs we actually
  # need.
  preAutoreconf = ''
    sed -i 's|PKG_CONFIG="$PKG_CONFIG --static"|:|' configure.ac
  '';

  meta = {
    description = "Texture and font conversion tools for 3DS homebrew development";
    homepage = "https://github.com/devkitPro/tex3ds";
    platforms = [ "x86_64-linux" ];
  };
}
