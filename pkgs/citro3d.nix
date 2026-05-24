{
  stdenv,
  citro3d-src,
  devkitARM,
  libctru,
  tools-3ds,
  general-tools,
}:

stdenv.mkDerivation {
  pname = "citro3d";
  version = citro3d-src.rev;

  src = citro3d-src;

  nativeBuildInputs = [
    devkitARM
    tools-3ds
    general-tools
  ];

  preBuild = ''
    export DEVKITPRO=$(mktemp -d)
    mkdir -p $DEVKITPRO/devkitARM
    ln -s ${devkitARM}/base_tools $DEVKITPRO/devkitARM/base_tools
    ln -s ${devkitARM}/base_rules $DEVKITPRO/devkitARM/base_rules
    ln -s ${devkitARM}/3ds_rules  $DEVKITPRO/devkitARM/3ds_rules
    ln -s ${devkitARM}/bin        $DEVKITPRO/devkitARM/bin
    ln -s ${libctru}              $DEVKITPRO/libctru
    export DEVKITARM=$DEVKITPRO/devkitARM
    export CTRULIB=${libctru}
  '';

  installPhase = ''
    make install DEVKITPRO=$DEVKITPRO DESTDIR=$TMPDIR/dest
    cp -rv $TMPDIR/dest/$DEVKITPRO/libctru/. $out
  '';

  meta = {
    description = "C3D graphics library for 3DS homebrew development";
    homepage = "https://github.com/devkitPro/citro3d";
    platforms = [ "x86_64-linux" ];
  };
}
