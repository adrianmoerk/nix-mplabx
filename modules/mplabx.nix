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
    # Create /etc/.mplab_ide/mchpsegusbmonitor symlink that MPLAB's startup script expects.
    # The Microchip installer normally places this during install, but NixOS manages /etc
    # so it never gets created, causing a startup error and broken compilation output.
    # MPLAB's startup script expects mchpsegusbmonitor at /etc/.mplab_ide/ but the
    # Microchip installer can't place it there on NixOS. Find it from any installed
    # version (preferring the configured default) and symlink it into place.
    system.activationScripts.mplabxUsbMonitor = ''
      MONITOR_DST="/etc/.mplab_ide/mchpsegusbmonitor"
      MONITOR_SRC=""

      # Try the configured default version first
      CANDIDATE="/opt/microchip/mplabx/${cfg.mplabxVersion}/mplab_platform/lib/mchpsegusbmonitor"
      if [ -f "$CANDIDATE" ]; then
        MONITOR_SRC="$CANDIDATE"
      else
        # Fall back to any installed version
        MONITOR_SRC=$(find /opt/microchip/mplabx -name "mchpsegusbmonitor" -type f 2>/dev/null | sort -V | tail -1)
      fi

      if [ -n "$MONITOR_SRC" ]; then
        mkdir -p /etc/.mplab_ide
        ln -sf "$MONITOR_SRC" "$MONITOR_DST"
      fi
    '';

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
