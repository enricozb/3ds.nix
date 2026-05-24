{
  stdenv,
  libctru-src,
  devkitARM,
  tools-3ds,
  general-tools,
}:

stdenv.mkDerivation {
  pname = "libctru";
  version = libctru-src.rev;

  src = "${libctru-src}/libctru";

  nativeBuildInputs = [
    devkitARM
    tools-3ds
    general-tools
  ];

  preBuild = ''
    # base_rules does `include $(DEVKITPRO)/devkitARM/base_tools`, so construct
    # a minimal DEVKITPRO with devkitARM/ pointing at the devkitARM store path
    export DEVKITPRO=$(mktemp -d)
    mkdir -p $DEVKITPRO/devkitARM
    ln -s ${devkitARM}/base_tools $DEVKITPRO/devkitARM/base_tools
    ln -s ${devkitARM}/base_rules $DEVKITPRO/devkitARM/base_rules
    ln -s ${devkitARM}/bin        $DEVKITPRO/devkitARM/bin
    export DEVKITARM=$DEVKITPRO/devkitARM
  '';

  installPhase = ''
    make install DEVKITPRO=$DEVKITPRO DESTDIR=$TMPDIR/dest
    cp -rv $TMPDIR/dest/$DEVKITPRO/libctru/. $out
  '';

  meta = {
    description = "Library for 3DS homebrew development";
    homepage = "https://github.com/devkitPro/libctru";
    platforms = [ "x86_64-linux" ];
  };
}
