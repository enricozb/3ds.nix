{ lib, stdenv, fetchurl, buildscripts, devkitarm-rules-src, devkitarm-crtls-src, gmp, mpfr, libmpc, isl, zlib, texinfo }:

let
  target = "arm-none-eabi";
  release = "67";

  binutils-src = fetchurl {
    url = "https://ftp.gnu.org/gnu/binutils/binutils-2.45.1.tar.xz";
    hash = "sha256-X+EB5v6dGP3slZYtge1nD97l834/SPC++Hvd+GJROqU=";
  };

  gcc-src = fetchurl {
    url = "https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz";
    hash = "sha256-Q4/ZloJrDIJIWinaA6ctcdbjVBqD7HAt9Ccfb+Al0k4=";
  };

  newlib-src = fetchurl {
    url = "https://sourceware.org/pub/newlib/newlib-4.5.0.20241231.tar.gz";
    hash = "sha256-M/EmBeAFSWWZbCXBOCs+RjsK+ReZAB9buMBjDy7IyFI=";
  };

in
stdenv.mkDerivation {
  pname = "devkitARM";
  version = buildscripts.rev;

  # We manage sources manually in the build phases
  dontUnpack = true;

  # nixpkgs hardening adds -Werror=format-security which breaks GCC's own libcpp build
  hardeningDisable = [ "format" ];

  nativeBuildInputs = [ texinfo ];
  buildInputs = [ gmp mpfr libmpc isl zlib ];

  buildPhase = ''
    # -------------------------------------------------------------------------
    # Extract sources
    # -------------------------------------------------------------------------
    tar -xf ${binutils-src}
    tar -xf ${gcc-src}
    tar -xf ${newlib-src}

    # -------------------------------------------------------------------------
    # Patch gcc and newlib
    # -------------------------------------------------------------------------
    patch -p1 -d gcc-15.2.0     -i ${buildscripts}/dkarm-eabi/patches/gcc-15.2.0.patch
    patch -p1 -d newlib-4.5.0.20241231 -i ${buildscripts}/dkarm-eabi/patches/newlib-4.5.0.20241231.patch

    mkdir -p build

    # -------------------------------------------------------------------------
    # Build binutils
    # -------------------------------------------------------------------------
    mkdir -p build/${target}/binutils
    pushd build/${target}/binutils
      ../../../binutils-2.45.1/configure \
        --prefix=$out \
        --target=${target} \
        --disable-nls \
        --disable-werror \
        --enable-lto \
        --enable-plugins \
        --enable-poison-system-directories
      make -j$NIX_BUILD_CORES
      make install
    popd

    # -------------------------------------------------------------------------
    # Build GCC stage 1 (C only, no libc yet)
    # -------------------------------------------------------------------------
    mkdir -p build/${target}/gcc
    pushd build/${target}/gcc
      CFLAGS_FOR_TARGET="-O2 -ffunction-sections -fdata-sections" \
      CXXFLAGS_FOR_TARGET="-O2 -ffunction-sections -fdata-sections" \
      LDFLAGS_FOR_TARGET="" \
      ../../../gcc-15.2.0/configure \
        --prefix=$out \
        --target=${target} \
        --enable-languages=c,c++,objc,lto \
        --with-gnu-as --with-gnu-ld --with-gcc \
        --with-march=armv4t \
        --enable-cxx-flags='-ffunction-sections' \
        --disable-libstdcxx-verbose \
        --enable-poison-system-directories \
        --enable-interwork --enable-multilib \
        --enable-threads --disable-win32-registry --disable-nls --disable-debug \
        --disable-libmudflap --disable-libssp --disable-libgomp \
        --disable-libstdcxx-pch \
        --enable-libstdcxx-time=yes \
        --enable-libstdcxx-filesystem-ts \
        --with-newlib \
        --with-headers=../../../newlib-4.5.0.20241231/newlib/libc/include \
        --enable-lto \
        --with-system-zlib \
        --disable-tm-clone-registry \
        --disable-__cxa_atexit \
        --with-gmp=${gmp} \
        --with-mpfr=${mpfr} \
        --with-mpc=${libmpc} \
        --with-isl=${isl} \
        --with-bugurl="https://devkitpro.org" \
        --with-pkgversion="devkitARM release ${release}"
      make -j$NIX_BUILD_CORES all-gcc
      make install-gcc
    popd

    # -------------------------------------------------------------------------
    # Build newlib
    # -------------------------------------------------------------------------
    # Make the just-installed stage1 gcc visible
    export PATH=$out/bin:$PATH

    mkdir -p build/${target}/newlib
    pushd build/${target}/newlib
      CFLAGS_FOR_TARGET="-O2 -ffunction-sections -fdata-sections" \
      ../../../newlib-4.5.0.20241231/configure \
        --prefix=$out \
        --target=${target} \
        --disable-newlib-supplied-syscalls \
        --enable-newlib-mb \
        --disable-newlib-wide-orient
      make -j$NIX_BUILD_CORES
      make install -j1
    popd

    # -------------------------------------------------------------------------
    # Build GCC stage 2 (full: C, C++, ObjC, LTO, with newlib)
    # -------------------------------------------------------------------------
    pushd build/${target}/gcc
      make -j$NIX_BUILD_CORES all
      make install
    popd

    rm -rf $out/${target}/sys-include

    # -------------------------------------------------------------------------
    # Install devkitarm-rules
    # -------------------------------------------------------------------------
    cp -v ${devkitarm-rules-src}/{3ds_rules,base_rules,base_tools,ds_rules,gba_rules,gp32_rules} $out/

    # -------------------------------------------------------------------------
    # Build and install devkitarm-crtls
    # -------------------------------------------------------------------------
    # Patch hardcoded /usr/bin/env bash out of base_tools
    chmod u+w $out/base_tools
    sed -i 's|/usr/bin/env bash|${stdenv.shell}|' $out/base_tools

    # base_rules does `include $(DEVKITPRO)/devkitARM/base_tools`, so construct
    # a minimal DEVKITPRO with devkitARM/ pointing at $out
    DEVKITPRO_TMP=$(mktemp -d)
    mkdir -p $DEVKITPRO_TMP/devkitARM
    ln -s $out/base_tools $DEVKITPRO_TMP/devkitARM/base_tools
    ln -s $out/base_rules $DEVKITPRO_TMP/devkitARM/base_rules
    ln -s $out/bin        $DEVKITPRO_TMP/devkitARM/bin

    cp -r ${devkitarm-crtls-src}/. crtls
    chmod -R u+w crtls
    pushd crtls
      make -j$NIX_BUILD_CORES \
        DEVKITPRO=$DEVKITPRO_TMP DEVKITARM=$out SHELL=$SHELL
      make install \
        DEVKITPRO=$DEVKITPRO_TMP DEVKITARM=$out SHELL=$SHELL \
        DESTDIR=$TMPDIR/crtls-dest
      cp -rv $TMPDIR/crtls-dest/opt/devkitpro/devkitARM/arm-none-eabi/lib/. \
        $out/${target}/lib/
    popd
  '';

  # Nothing to do in installPhase — everything installed into $out during buildPhase
  dontInstall = true;

  meta = {
    description = "devkitARM r${release} — ARM cross-compiler toolchain for 3DS/GBA/DS development";
    homepage = "https://devkitpro.org";
    platforms = [ "x86_64-linux" ];
  };
}
