{
  stdenv,
  cmake,
  devkitARM,
  libctru,
  citro3d,
  libctru-merged, # symlinkJoin of libctru + citro3d
  tools-3ds,
  general-tools,
  picasso,
  dkp-cmake,
  citro2d-src,
}:

stdenv.mkDerivation {
  pname = "citro2d";
  version = citro2d-src.rev;

  src = citro2d-src;

  nativeBuildInputs = [
    cmake
    devkitARM
    tools-3ds # smdhtool, 3dsxtool
    general-tools # bin2s
    picasso # shader compiler
  ];

  dontFixup = true;

  preConfigure = ''
    export DEVKITPRO=$(mktemp -d)
    mkdir -p $DEVKITPRO/devkitARM
    ln -s ${devkitARM}/bin           $DEVKITPRO/devkitARM/bin
    ln -s ${devkitARM}/arm-none-eabi $DEVKITPRO/devkitARM/arm-none-eabi
    ln -s ${dkp-cmake}               $DEVKITPRO/cmake
    # citro2d includes citro3d.h, so DEVKITPRO/libctru must contain both.
    # libctru-merged is a symlinkJoin of libctru + citro3d passed from the flake.
    ln -s ${libctru-merged} $DEVKITPRO/libctru

    # tools/bin — picked up by dkp-toolchain-common.cmake for bin2s
    mkdir -p $DEVKITPRO/tools/bin
    ln -s ${general-tools}/bin/bin2s $DEVKITPRO/tools/bin/bin2s
    ln -s ${tools-3ds}/bin/smdhtool  $DEVKITPRO/tools/bin/smdhtool
    ln -s ${tools-3ds}/bin/3dsxtool  $DEVKITPRO/tools/bin/3dsxtool
    ln -s ${picasso}/bin/picasso     $DEVKITPRO/tools/bin/picasso
  '';

  cmakeFlags = [
    "-DCMAKE_TOOLCHAIN_FILE=${dkp-cmake}/3DS.cmake"
    # Skip the link-test step of cmake's compiler detection.
    # See box2d.nix for explanation.
    "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    # Override host-compiler flags injected by nixpkgs cmake hook
    "-DCMAKE_C_COMPILER=${devkitARM}/bin/arm-none-eabi-gcc"
    "-DCMAKE_CXX_COMPILER=${devkitARM}/bin/arm-none-eabi-g++"
    "-DCMAKE_ASM_COMPILER=${devkitARM}/bin/arm-none-eabi-gcc"
    "-DCMAKE_AR=${devkitARM}/bin/arm-none-eabi-gcc-ar"
    "-DCMAKE_RANLIB=${devkitARM}/bin/arm-none-eabi-gcc-ranlib"
    "-DCMAKE_STRIP=${devkitARM}/bin/arm-none-eabi-strip"
    # picasso and bin2s paths for cmake functions
    "-DCTR_PICASSO_EXE=${picasso}/bin/picasso"
    "-DDKP_BIN2S=${general-tools}/bin/bin2s"
  ];

  meta = {
    description = "citro2d — 2D graphics library for 3DS homebrew (built on citro3d)";
    homepage = "https://github.com/devkitPro/citro2d";
    platforms = [ "x86_64-linux" ];
  };
}
