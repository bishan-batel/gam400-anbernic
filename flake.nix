{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
    self,
    rust-overlay,
    flake-utils,
    nixpkgs,
    }:
    flake-utils.lib.eachDefaultSystem (system: let 
      pkgs = nixpkgs.legacyPackages.${system};
    in
      # TODO: Make this use the toolchain file for more compatibility
      {
      devShells.default =
        let
          pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
          platformDeps = (if pkgs.stdenv.isDarwin then with pkgsCross; [ 
            libiconv 
          ] else with pkgsCross; [ 
              libdrm.dev 
              libdecor.dev
              mesa
            ]);
          rust-bin = rust-overlay.lib.mkRustBin { } pkgsCross.buildPackages;
          in
            pkgsCross.callPackage ( { mkShell, pkg-config, qemu, openssl, stdenv, }:
          mkShell {
            nativeBuildInputs = [
              (rust-bin.fromRustupToolchainFile ./toolchain.toml)
                pkg-config
              ] ++ platformDeps;

              depsBuildBuild = [ qemu ];

              buildInputs = [ 
                pkg-config
                openssl 
                pkgsCross.stdenv.cc
              ] ++ 
              [
                pkgs.cmake
              ];

              env = {
                LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [ ]);
                DYLD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [ ]);
                
                CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${pkgsCross.stdenv.cc.targetPrefix}cc";
                CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-aarch64";
              };
            }
          ) { };
    });
}
