# Wrapper scripts for XC32 compiler tools
# These invoke the tools installed in /opt/microchip/xc32/
{
  pkgs,
  xc32Version,
}: let
  xc32BasePath = "/opt/microchip/xc32/${xc32Version}";

  # Common wrapper for XC32 tools
  makeXc32Wrapper = name:
    pkgs.writeShellScriptBin name ''
      XC32_PATH="${xc32BasePath}"

      if [ ! -d "$XC32_PATH" ]; then
        echo "Error: XC32 not found at $XC32_PATH"
        echo "Run 'mplab-install' to install the XC32 compiler"
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
