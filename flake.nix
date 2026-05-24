{
  description = "3DS development using devkitPro";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    buildscripts = {
      url = "github:devkitPro/buildscripts/devkitARM_r67";
      flake = false;
    };
    devkitarm-rules-src = {
      url = "github:devkitPro/devkitarm-rules/v1.6.1";
      flake = false;
    };
    devkitarm-crtls-src = {
      url = "github:devkitPro/devkitarm-crtls/v1.2.7";
      flake = false;
    };
    libctru-src = {
      url = "github:devkitPro/libctru/v2.7.0";
      flake = false;
    };
    tools-3ds-src = {
      url = "github:devkitPro/3dstools/v1.3.1";
      flake = false;
    };
    dslink-src = {
      url = "github:devkitPro/3dslink/v0.6.3";
      flake = false;
    };
    general-tools-src = {
      url = "github:devkitPro/general-tools/v1.4.4";
      flake = false;
    };
    citro3d-src = {
      url = "github:devkitPro/citro3d/v1.7.1";
      flake = false;
    };
    citro2d-src = {
      url = "github:devkitPro/citro2d/v1.7.0";
      flake = false;
    };
    picasso-src = {
      url = "github:devkitPro/picasso/82cf7d95fe904bab54a69c723a9e21a06677f290";
      flake = false;
    };
    dkp-pacman-packages = {
      # devkitPro cmake toolchain files (devkitarm-cmake, 3ds-cmake, dkp-cmake-common-utils)
      url = "github:devkitPro/pacman-packages/e7929f40084802426f8b5fa202e0b65e2317014c";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      rust-overlay,
      buildscripts,
      devkitarm-rules-src,
      devkitarm-crtls-src,
      libctru-src,
      tools-3ds-src,
      general-tools-src,
      dslink-src,
      picasso-src,
      citro3d-src,
      citro2d-src,
      dkp-pacman-packages,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };

      rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      craneLib = (crane.mkLib pkgs).overrideToolchain (_: rustToolchain);

      devkitARM = pkgs.callPackage ./pkgs/devkitARM.nix {
        inherit buildscripts devkitarm-rules-src devkitarm-crtls-src;
      };

      tools-3ds = pkgs.callPackage ./pkgs/3dstools.nix { inherit tools-3ds-src; };
      picasso = pkgs.callPackage ./pkgs/picasso.nix { inherit picasso-src; };
      dslink = pkgs.callPackage ./pkgs/3dslink.nix { inherit dslink-src; };
      general-tools = pkgs.callPackage ./pkgs/general-tools.nix { inherit general-tools-src; };
      libctru = pkgs.callPackage ./pkgs/libctru.nix {
        inherit
          libctru-src
          devkitARM
          tools-3ds
          general-tools
          ;
      };
      citro3d = pkgs.callPackage ./pkgs/citro3d.nix {
        inherit
          citro3d-src
          devkitARM
          libctru
          tools-3ds
          general-tools
          ;
      };

      dkp-cmake = pkgs.callPackage ./pkgs/dkp-cmake.nix { inherit dkp-pacman-packages; };

      # libctru + citro3d merged — needed as DEVKITPRO/libctru for citro2d build
      libctru-merged = pkgs.symlinkJoin {
        name = "libctru-merged";
        paths = [ libctru citro3d ];
      };

      citro2d = pkgs.callPackage ./pkgs/citro2d.nix {
        inherit
          citro2d-src
          devkitARM
          libctru
          citro3d
          libctru-merged
          tools-3ds
          general-tools
          picasso
          dkp-cmake
          ;
      };

      box2d = pkgs.callPackage ./pkgs/box2d.nix {
        inherit devkitARM dkp-cmake;
      };

      # Merge libctru, citro3d, and citro2d into a single libctru prefix
      libctru-full = pkgs.symlinkJoin {
        name = "libctru-full";
        paths = [
          libctru
          citro3d
          citro2d
        ];
      };

      # portlibs/3ds holds cross-compiled port libraries (box2d, etc.)
      portlibs-3ds = pkgs.symlinkJoin {
        name = "portlibs-3ds";
        paths = [ box2d ];
      };

      # DEVKITPRO must be a directory with devkitARM/, libctru/,
      # portlibs/3ds/, tools/bin/, and cmake/ inside it.
      devkitpro = pkgs.runCommand "devkitpro" { } ''
        mkdir -p $out/portlibs $out/tools/bin
        ln -s ${devkitARM}     $out/devkitARM
        ln -s ${libctru-full}  $out/libctru
        ln -s ${portlibs-3ds}  $out/portlibs/3ds
        ln -s ${dkp-cmake}     $out/cmake
        ln -s ${general-tools}/bin/bin2s  $out/tools/bin/bin2s
        ln -s ${tools-3ds}/bin/smdhtool   $out/tools/bin/smdhtool
        ln -s ${tools-3ds}/bin/3dsxtool   $out/tools/bin/3dsxtool
        ln -s ${picasso}/bin/picasso      $out/tools/bin/picasso
      '';

      dev-packages = [
        devkitARM
        tools-3ds
        general-tools
        dslink
        picasso
      ];
      DEVKITPRO = "${devkitpro}";
      DEVKITARM = "${devkitpro}/devkitARM";
      CTRULIB = "${devkitpro}/libctru";
    in
    {
      devShells.${system} = {
        default = pkgs.mkShell {
          name = "3ds-dev";
          inherit DEVKITPRO DEVKITARM CTRULIB;

          packages = dev-packages;
        };

        rust = craneLib.devShell {
          name = "rust3ds-dev";
          inherit DEVKITPRO DEVKITARM CTRULIB;

          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

          packages = dev-packages ++ [
            pkgs.cargo-3ds
            pkgs.llvmPackages.libclang
            pkgs.llvmPackages.clang
          ];
        };
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
