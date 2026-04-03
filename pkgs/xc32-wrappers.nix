# Wrapper scripts for XC32 compiler tools
# Version can be overridden via XC32_VERSION environment variable
{
  pkgs,
  xc32Version,
}: let
  defaultVersion = xc32Version;

  # Common wrapper for XC32 tools with auto-detection
  makeXc32Wrapper = name:
    pkgs.writeShellScriptBin name ''
      INSTALL_DIR="/opt/microchip/xc32"

      # Use environment variable, or find latest installed, or fall back to default
      if [ -n "$XC32_VERSION" ]; then
        VERSION="$XC32_VERSION"
      elif [ -d "$INSTALL_DIR" ]; then
        # Find latest installed version
        VERSION=$(ls -1 "$INSTALL_DIR" 2>/dev/null | sort -V | tail -1)
      fi
      VERSION="''${VERSION:-${defaultVersion}}"

      XC32_PATH="$INSTALL_DIR/$VERSION"

      if [ ! -d "$XC32_PATH" ]; then
        echo "Error: XC32 not found at $XC32_PATH" >&2
        if [ -d "$INSTALL_DIR" ]; then
          echo "Available versions: $(ls -1 "$INSTALL_DIR" 2>/dev/null | tr '\n' ' ')" >&2
        fi
        echo "Run 'mplab-install' to install the XC32 compiler" >&2
        echo "Or set XC32_VERSION environment variable to select a version" >&2
        exit 1
      fi

      export PATH="$XC32_PATH/bin:$PATH"
      export XC32_TOOLCHAIN_ROOT="$XC32_PATH"

      exec "$XC32_PATH/bin/${name}" "$@"
    '';

  # List of XC32 tools to wrap
  xc32Tools = [
    "xc32-gcc"
    "xc32-g++"
    "xc32-as"
    "xc32-ld"
    "xc32-ar"
    "xc32-objcopy"
    "xc32-objdump"
    "xc32-size"
    "xc32-nm"
    "xc32-strip"
    "xc32-strings"
    "xc32-readelf"
    "xc32-addr2line"
    "xc32-ranlib"
    "xc32-c++filt"
  ];

  wrappers = map makeXc32Wrapper xc32Tools;
in
  pkgs.symlinkJoin {
    name = "xc32-wrappers-${xc32Version}";
    paths = wrappers;
    meta = with pkgs.lib; {
      description = "Wrapper scripts for Microchip XC32 compiler";
      homepage = "https://www.microchip.com/xc32";
      platforms = ["x86_64-linux"];
      license = licenses.mit;
    };
  }
