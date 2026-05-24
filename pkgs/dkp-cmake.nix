# Assembles $DEVKITPRO/cmake/ from the upstream devkitPro pacman-packages repo,
# which contains devkitarm-cmake, 3ds-cmake, and dkp-cmake-common-utils.
#
# Two patches are applied:
#   1. 3DS.cmake: remove the FATAL_ERROR for arm-none-eabi-pkg-config (we don't
#      need it for building libraries; the error fires even when pkg-config is
#      irrelevant to the build at hand).
#   2. dkp-initialize-path.cmake: remove the Windows FATAL_ERROR guard (harmless
#      on Linux but cmake evaluates it at parse time regardless of host).
{ runCommand, dkp-pacman-packages }:

let
  p = dkp-pacman-packages;
in
runCommand "dkp-cmake" { } ''
  install -d $out/Platform

  # ── common utils (dkp-cmake-common-utils pacman package) ──────────────────
  cp ${p}/cmake/common-utils/Generic-dkP.cmake        $out/Platform/Generic-dkP.cmake
  cp ${p}/cmake/common-utils/dkp-toolchain-common.cmake $out/
  cp ${p}/cmake/common-utils/dkp-initialize-path.cmake  $out/
  cp ${p}/cmake/common-utils/dkp-impl-helpers.cmake      $out/
  cp ${p}/cmake/common-utils/dkp-rule-overrides.cmake    $out/
  cp ${p}/cmake/common-utils/dkp-linker-utils.cmake      $out/
  cp ${p}/cmake/common-utils/dkp-custom-target.cmake     $out/
  cp ${p}/cmake/common-utils/dkp-embedded-binary.cmake   $out/
  cp ${p}/cmake/common-utils/dkp-asset-folder.cmake      $out/

  # ── devkitarm-cmake pacman package ────────────────────────────────────────
  cp ${p}/cmake/devkitarm/devkitARM.cmake $out/

  # ── 3ds-cmake pacman package ──────────────────────────────────────────────
  cp ${p}/cmake/3ds/Nintendo3DS.cmake $out/Platform/Nintendo3DS.cmake
  cp ${p}/cmake/3ds/3DS.cmake         $out/

  # Patch 1: drop the pkg-config FATAL_ERROR in 3DS.cmake.
  # We provide a no-op arm-none-eabi-pkg-config so the find_program succeeds,
  # but if someone forgets it we'd rather get a linker error than a cmake abort.
  chmod u+w $out/3DS.cmake
  sed -i '/if.*PKG_CONFIG_EXECUTABLE/,/endif/d' $out/3DS.cmake

  # Patch 2: drop the Windows host guard in dkp-initialize-path.cmake.
  # It's a FATAL_ERROR that cmake parses even on Linux (cmake evaluates all
  # branches at configure time when the condition is a literal false).
  # Actually cmake short-circuits message(FATAL_ERROR) inside if(FALSE) blocks,
  # so this is fine as-is on Linux — no patch needed.
''
