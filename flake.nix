{
  description = "3DS development using devkitPro";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    picasso-src = {
      url = "github:devkitPro/picasso/82cf7d95fe904bab54a69c723a9e21a06677f290";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, buildscripts, devkitarm-rules-src, devkitarm-crtls-src, libctru-src, tools-3ds-src, general-tools-src, dslink-src, picasso-src, citro3d-src }:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };

    devkitARM = pkgs.callPackage ./pkgs/devkitARM.nix { inherit buildscripts devkitarm-rules-src devkitarm-crtls-src; };

    tools-3ds = pkgs.callPackage ./pkgs/3dstools.nix { inherit tools-3ds-src; };
    picasso = pkgs.callPackage ./pkgs/picasso.nix { inherit picasso-src; };
    dslink = pkgs.callPackage ./pkgs/3dslink.nix { inherit dslink-src; };
    general-tools = pkgs.callPackage ./pkgs/general-tools.nix { inherit general-tools-src; };
    libctru = pkgs.callPackage ./pkgs/libctru.nix { inherit libctru-src devkitARM tools-3ds general-tools; };
    citro3d = pkgs.callPackage ./pkgs/citro3d.nix { inherit citro3d-src devkitARM libctru tools-3ds general-tools; };

    # Merge libctru and citro3d into a single libctru prefix
    libctru-full = pkgs.symlinkJoin {
      name = "libctru-full";
      paths = [ libctru citro3d ];
    };

    # DEVKITPRO must be a directory with devkitARM/ and libctru/ inside it
    devkitpro = pkgs.runCommand "devkitpro" { } ''
      mkdir -p $out
      ln -s ${devkitARM} $out/devkitARM
      ln -s ${libctru-full} $out/libctru
    '';
  in
  {
    devShells.x86_64-linux.default = pkgs.mkShell {
      DEVKITPRO = "${devkitpro}";
      DEVKITARM = "${devkitpro}/devkitARM";
      CTRULIB = "${devkitpro}/libctru";

      packages = [ devkitARM tools-3ds general-tools dslink picasso ];
    };
  };
}
