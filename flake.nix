{
  description = "MPLAB X IDE, IPE, and XC32 compiler for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Default versions (can be overridden)
    defaultMplabxVersion = "v6.30";
    defaultXc32Version = "v5.10";

    # Package builders with configurable versions
    mkMplabxFhs = import ./pkgs/mplabx-fhs.nix {inherit pkgs;};

    mkMplabWrappers = {mplabxVersion ? defaultMplabxVersion}:
      import ./pkgs/mplab-wrappers.nix {
        inherit pkgs mplabxVersion;
        mplabxFhs = mkMplabxFhs;
      };

    mkXc32Wrappers = {xc32Version ? defaultXc32Version}:
      import ./pkgs/xc32-wrappers.nix {
        inherit pkgs xc32Version;
      };

    mkMplabInstall = {
      mplabxVersion ? defaultMplabxVersion,
      xc32Version ? defaultXc32Version,
    }:
      import ./pkgs/mplab-install.nix {
        inherit pkgs mplabxVersion xc32Version;
        mplabxFhs = mkMplabxFhs;
      };
  in {
    # Packages with default versions
    packages.${system} = {
      mplabx-fhs = mkMplabxFhs;
      mplab-wrappers = mkMplabWrappers {};
      xc32-wrappers = mkXc32Wrappers {};
      mplab-install = mkMplabInstall {};

      # Convenience bundle with all tools
      default = pkgs.symlinkJoin {
        name = "mplabx-tools";
        paths = [
          (mkMplabWrappers {})
          (mkXc32Wrappers {})
          (mkMplabInstall {})
        ];
      };
    };

    # Parameterized package builders for custom versions
    lib.${system} = {
      inherit mkMplabxFhs mkMplabWrappers mkXc32Wrappers mkMplabInstall;
    };

    # NixOS module
    nixosModules.default = import ./modules/mplabx.nix;
    nixosModules.mplabx = import ./modules/mplabx.nix;

    # Overlay for use with nixpkgs
    overlays.default = final: prev: {
      mplabx-fhs = mkMplabxFhs;
      mplab-wrappers = mkMplabWrappers {};
      xc32-wrappers = mkXc32Wrappers {};
      mplab-install = mkMplabInstall {};
    };
  };
}
