# Wrappers for MPLAB X IDE and IPE (Integrated Programming Environment)
# Supports PICkit4/PICkit5 programming
# Version can be overridden via MPLABX_VERSION environment variable
{
  pkgs,
  mplabxVersion,
  mplabxFhs,
}: let
  defaultVersion = mplabxVersion;

  # MPLAB X IDE wrapper - runs in FHS environment with bundled Java 8
  ideWrapper = pkgs.writeShellScriptBin "mplab-ide" ''
    INSTALL_DIR="/opt/microchip/mplabx"

    # Use environment variable, or find latest installed, or fall back to default
    if [ -n "$MPLABX_VERSION" ]; then
      VERSION="$MPLABX_VERSION"
    elif [ -d "$INSTALL_DIR" ]; then
      # Find latest installed version
      VERSION=$(ls -1 "$INSTALL_DIR" 2>/dev/null | sort -V | tail -1)
    fi
    VERSION="''${VERSION:-${defaultVersion}}"

    MPLABX_PATH="$INSTALL_DIR/$VERSION"

    if [ ! -d "$MPLABX_PATH" ]; then
      echo "Error: MPLAB X IDE not found at $MPLABX_PATH"
      if [ -d "$INSTALL_DIR" ]; then
        echo "Available versions: $(ls -1 "$INSTALL_DIR" 2>/dev/null | tr '\n' ' ')"
      fi
      echo "Run 'mplab-install' to install MPLAB X IDE/IPE"
      echo "Or set MPLABX_VERSION environment variable to select a version"
      exit 1
    fi

    # Find bundled Java
    JAVA_HOME=$(find "$MPLABX_PATH/sys/java" -maxdepth 1 -name "zulu*" -type d 2>/dev/null | head -1)
    if [ -z "$JAVA_HOME" ]; then
      echo "Error: Bundled Java not found in $MPLABX_PATH/sys/java"
      exit 1
    fi

    echo "Starting MPLAB X IDE $VERSION..."
    exec ${mplabxFhs}/bin/mplabx-env -c "export _JAVA_AWT_WM_NONREPARENTING=1 && $MPLABX_PATH/mplab_platform/bin/mplab_ide --jdkhome $JAVA_HOME $*"
  '';

  # IPE GUI wrapper - runs in FHS environment with bundled Java 8
  ipeGuiWrapper = pkgs.writeShellScriptBin "mplab-ipe-gui" ''
    INSTALL_DIR="/opt/microchip/mplabx"

    # Use environment variable, or find latest installed, or fall back to default
    if [ -n "$MPLABX_VERSION" ]; then
      VERSION="$MPLABX_VERSION"
    elif [ -d "$INSTALL_DIR" ]; then
      VERSION=$(ls -1 "$INSTALL_DIR" 2>/dev/null | sort -V | tail -1)
    fi
    VERSION="''${VERSION:-${defaultVersion}}"

    MPLABX_PATH="$INSTALL_DIR/$VERSION"

    if [ ! -d "$MPLABX_PATH" ]; then
      echo "Error: MPLAB X not found at $MPLABX_PATH"
      if [ -d "$INSTALL_DIR" ]; then
        echo "Available versions: $(ls -1 "$INSTALL_DIR" 2>/dev/null | tr '\n' ' ')"
      fi
      echo "Run 'mplab-install' to install MPLAB X IDE/IPE"
      exit 1
    fi

    # Find bundled Java
    JAVA_HOME=$(find "$MPLABX_PATH/sys/java" -maxdepth 1 -name "zulu*" -type d 2>/dev/null | head -1)
    if [ -z "$JAVA_HOME" ]; then
      echo "Error: Bundled Java not found"
      exit 1
    fi

    echo "Starting MPLAB IPE GUI $VERSION..."
    exec ${mplabxFhs}/bin/mplabx-env -c "export _JAVA_AWT_WM_NONREPARENTING=1 && $MPLABX_PATH/mplab_platform/bin/mplab_ipe --jdkhome $JAVA_HOME $*"
  '';

  # IPE command-line wrapper - uses bundled Java 8
  ipeWrapper = pkgs.writeShellScriptBin "mplab-ipe" ''
    INSTALL_DIR="/opt/microchip/mplabx"

    # Use environment variable, or find latest installed, or fall back to default
    if [ -n "$MPLABX_VERSION" ]; then
      VERSION="$MPLABX_VERSION"
    elif [ -d "$INSTALL_DIR" ]; then
      VERSION=$(ls -1 "$INSTALL_DIR" 2>/dev/null | sort -V | tail -1)
    fi
    VERSION="''${VERSION:-${defaultVersion}}"

    MPLABX_PATH="$INSTALL_DIR/$VERSION"
    IPE_PATH="$MPLABX_PATH/mplab_platform/mplab_ipe"

    if [ ! -d "$IPE_PATH" ]; then
      echo "Error: MPLAB IPE not found at $IPE_PATH"
      if [ -d "$INSTALL_DIR" ]; then
        echo "Available versions: $(ls -1 "$INSTALL_DIR" 2>/dev/null | tr '\n' ' ')"
      fi
      echo "Run 'mplab-install' to install MPLAB X IDE/IPE"
      exit 1
    fi

    # Find bundled Java
    JAVA_HOME=$(find "$MPLABX_PATH/sys/java" -maxdepth 1 -name "zulu*" -type d 2>/dev/null | head -1)
    if [ -z "$JAVA_HOME" ]; then
      echo "Error: Bundled Java not found"
      exit 1
    fi

    # IPE classpath
    IPE_JAR="$IPE_PATH/lib/mplab_ipe.jar"
    if [ ! -f "$IPE_JAR" ]; then
      IPE_JAR="$IPE_PATH/ipecmd.jar"
    fi

    if [ ! -f "$IPE_JAR" ]; then
      echo "Error: IPE JAR not found"
      exit 1
    fi

    exec ${mplabxFhs}/bin/mplabx-env -c "export JAVA_HOME=$JAVA_HOME && export PATH=$JAVA_HOME/bin:\$PATH && export _JAVA_AWT_WM_NONREPARENTING=1 && $JAVA_HOME/bin/java -jar $IPE_JAR $*"
  '';

  # Version listing helper
  versionWrapper = pkgs.writeShellScriptBin "mplab-versions" ''
    echo "=== Installed Microchip Tools ==="
    echo ""

    MPLABX_DIR="/opt/microchip/mplabx"
    XC32_DIR="/opt/microchip/xc32"

    if [ -d "$MPLABX_DIR" ]; then
      echo "MPLAB X IDE versions:"
      for v in $(ls -1 "$MPLABX_DIR" 2>/dev/null | sort -V); do
        echo "  $v"
      done
    else
      echo "MPLAB X IDE: not installed"
    fi

    echo ""

    if [ -d "$XC32_DIR" ]; then
      echo "XC32 Compiler versions:"
      for v in $(ls -1 "$XC32_DIR" 2>/dev/null | sort -V); do
        echo "  $v"
      done
    else
      echo "XC32 Compiler: not installed"
    fi

    echo ""
    echo "Set MPLABX_VERSION or XC32_VERSION to use a specific version."
    echo "Example: MPLABX_VERSION=v6.25 mplab-ide"
  '';
in
  pkgs.symlinkJoin {
    name = "mplab-wrappers-${mplabxVersion}";
    paths = [ideWrapper ipeWrapper ipeGuiWrapper versionWrapper];
    meta = with pkgs.lib; {
      description = "Wrapper scripts for MPLAB X IDE and IPE programmer";
      homepage = "https://www.microchip.com/mplab/mplab-x-ide";
      platforms = ["x86_64-linux"];
      license = licenses.mit;
    };
  }
