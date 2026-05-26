# NixOS module for MPLAB X development environment
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.mplabx;
in {
  options.programs.mplabx = {
    enable = mkEnableOption "MPLAB X IDE and XC compiler support";

    mplabxVersion = mkOption {
      type = types.str;
      default = "v6.30";
      description = "MPLAB X IDE version to use";
    };

    xc32Version = mkOption {
      type = types.str;
      default = "v5.10";
      description = "XC32 compiler version to use";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Users to add to the plugdev group for USB programmer access";
    };
  };

  config = mkIf cfg.enable {
    # MPLAB's startup script expects /etc/.mplab_ide/mchpsegusbmonitor to exist.
    # The Microchip installer normally places it there, but on NixOS this doesn't
    # persist (the installer runs inside an FHS env and /etc is Nix-managed).
    # Provide a no-op stub so the startup script doesn't error out.
    environment.etc.".mplab_ide/mchpsegusbmonitor" = {
      text = ''
        #!/bin/sh
        exit 0
      '';
      mode = "0755";
    };

    # udev rules for Microchip programmers
    services.udev.extraRules = ''
      # Microchip PICkit 4
      SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="9012", MODE="0666", GROUP="plugdev"
      # Microchip PICkit 5
      SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="9036", MODE="0666", GROUP="plugdev"
      # Microchip MPLAB SNAP
      SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="9018", MODE="0666", GROUP="plugdev"
      # Microchip ICD 4
      SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="9015", MODE="0666", GROUP="plugdev"
      # Microchip ICD 5
      SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="9037", MODE="0666", GROUP="plugdev"
      # Microchip REAL ICE
      SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="9004", MODE="0666", GROUP="plugdev"
      # Generic Microchip tools (catch-all for vendor ID)
      SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", MODE="0666", GROUP="plugdev"
    '';

    # Ensure plugdev group exists
    users.groups.plugdev = {};

    # Add specified users to plugdev group
    users.users = builtins.listToAttrs (map (user: {
        name = user;
        value = {extraGroups = ["plugdev"];};
      })
      cfg.users);
  };
}
