{
  stdenv,
  fetchurl,
  cmake,
  devkitARM,
  dkp-cmake,
}:

let
  version = "2.4.1";
in
stdenv.mkDerivation {
  pname = "3ds-box2d";
  inherit version;

  src = fetchurl {
    url = "https://github.com/erincatto/box2d/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-1rRlD/iX7h6tJ893pZM+oZfL7vZwVjjdGBrcLoFrI8I=";
  };

  nativeBuildInputs = [
    cmake
    devkitARM
  ];

  # cmake cross-compile: don't try to run built binaries
  dontFixup = true;

  preConfigure = ''
    export DEVKITPRO=$(mktemp -d)
    mkdir -p $DEVKITPRO/devkitARM
    ln -s ${devkitARM}/bin         $DEVKITPRO/devkitARM/bin
    ln -s ${devkitARM}/arm-none-eabi $DEVKITPRO/devkitARM/arm-none-eabi
    ln -s ${dkp-cmake}             $DEVKITPRO/cmake
  '';

  cmakeFlags = [
    "-DCMAKE_TOOLCHAIN_FILE=${dkp-cmake}/3DS.cmake"
    # Skip the link-test step of cmake's compiler detection.
    # Without this, cmake tries to link a test executable against -lctru (a
    # standard library on this platform) which fails because the try-compile
    # sandbox doesn't have the full sysroot. STATIC_LIBRARY tells cmake to only
    # compile, not link, during compiler detection — without affecting the flags
    # used for the actual build (unlike DKP_PLATFORM_BOOTSTRAP which suppresses
    # the platform include/link flags for the whole build).
    "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
    "-DBOX2D_BUILD_DOCS=OFF"
    "-DBOX2D_BUILD_UNIT_TESTS=OFF"
    "-DBOX2D_BUILD_TESTBED=OFF"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    # Override host-compiler flags injected by nixpkgs cmake hook
    "-DCMAKE_C_COMPILER=${devkitARM}/bin/arm-none-eabi-gcc"
    "-DCMAKE_CXX_COMPILER=${devkitARM}/bin/arm-none-eabi-g++"
    "-DCMAKE_ASM_COMPILER=${devkitARM}/bin/arm-none-eabi-gcc"
    "-DCMAKE_AR=${devkitARM}/bin/arm-none-eabi-gcc-ar"
    "-DCMAKE_RANLIB=${devkitARM}/bin/arm-none-eabi-gcc-ranlib"
    "-DCMAKE_STRIP=${devkitARM}/bin/arm-none-eabi-strip"
  ];

  meta = {
    description = "Box2D 2D physics engine cross-compiled for Nintendo 3DS (arm-none-eabi)";
    homepage = "https://github.com/erincatto/box2d";
    platforms = [ "x86_64-linux" ];
  };
}
