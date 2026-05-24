{
  description = "3DS development using devkitPro";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    buildscripts = {
      url = "github:devkitPro/buildscripts/1d87636f62716a8866e5ce557cba5c3fa0f43329";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, buildscripts }: {
    devShells.x86_64-linux.default =
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in
      pkgs.mkShell {
        name = "3ds-dev";

        packages = [ ];
      };
  };
}
