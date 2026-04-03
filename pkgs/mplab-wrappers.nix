# Wrappers for MPLAB X IDE and IPE (Integrated Programming Environment)
# Supports PICkit4/PICkit5 programming
{
  pkgs,
  mplabxVersion,
  mplabxFhs,
}: let
  mplabxBasePath = "/opt/microchip/mplabx/${mplabxVersion}";

  # Bundled Java 8 path (update this if Microchip changes the bundled JRE)
  bundledJava = "${mplabxBasePath}/sys/java/zulu8.86.0.25-ca-fx-jre8.0.452-linux_x64";

  # MPLAB X IDE wrapper - runs in FHS environment with bundled Java 8
  ideWrapper = pkgs.writeShellScriptBin "mplab-ide" ''
    MPLABX_PATH="${mplabxBasePath}"

    if [ ! -d "$MPLABX_PATH" ]; then
      echo "Error: MPLAB X IDE not found at $MPLABX_PATH"
      echo "Run 'mplab-install' to install MPLAB X IDE/IPE"
      exit 1
    fi

    # Find bundled Java (path may vary between versions)
    JAVA_HOME=$(find "$MPLABX_PATH/sys/java" -maxdepth 1 -name "zulu*" -type d 2>/dev/null | head -1)
    if [ -z "$JAVA_HOME" ]; then
      JAVA_HOME="${bundledJava}"
    fi

    # Force use of bundled Java 8 via --jdkhome flag
    exec ${mplabxFhs}/bin/mplabx-env -c "export _JAVA_AWT_WM_NONREPARENTING=1 && $MPLABX_PATH/mplab_platform/bin/mplab_ide --jdkhome $JAVA_HOME $*"
  '';

  # IPE GUI wrapper - runs in FHS environment with bundled Java 8
  ipeGuiWrapper = pkgs.writeShellScriptBin "mplab-ipe-gui" ''
    MPLABX_PATH="${mplabxBasePath}"

    if [ ! -d "$MPLABX_PATH" ]; then
      echo "Error: MPLAB X not found at $MPLABX_PATH"
      echo "Run 'mplab-install' to install MPLAB X IDE/IPE"
      exit 1
    fi

    # Find bundled Java
    JAVA_HOME=$(find "$MPLABX_PATH/sys/java" -maxdepth 1 -name "zulu*" -type d 2>/dev/null | head -1)
    if [ -z "$JAVA_HOME" ]; then
      JAVA_HOME="${bundledJava}"
    fi

    exec ${mplabxFhs}/bin/mplabx-env -c "export _JAVA_AWT_WM_NONREPARENTING=1 && $MPLABX_PATH/mplab_platform/bin/mplab_ipe --jdkhome $JAVA_HOME $*"
  '';

  # IPE command-line wrapper - uses bundled Java 8
  ipeWrapper = pkgs.writeShellScriptBin "mplab-ipe" ''
    MPLABX_PATH="${mplabxBasePath}"
    IPE_PATH="$MPLABX_PATH/mplab_platform/mplab_ipe"

    if [ ! -d "$IPE_PATH" ]; then
      echo "Error: MPLAB IPE not found at $IPE_PATH"
      echo "Run 'mplab-install' to install MPLAB X IDE/IPE"
      exit 1
    fi

    # Find bundled Java
    JAVA_HOME=$(find "$MPLABX_PATH/sys/java" -maxdepth 1 -name "zulu*" -type d 2>/dev/null | head -1)
    if [ -z "$JAVA_HOME" ]; then
      JAVA_HOME="${bundledJava}"
    fi

    # IPE classpath
    IPE_JAR="$IPE_PATH/lib/mplab_ipe.jar"
    if [ ! -f "$IPE_JAR" ]; then
      IPE_JAR="$IPE_PATH/ipecmd.jar"
    fi

    if [ ! -f "$IPE_JAR" ]; then
      echo "Error: IPE JAR not found"
      echo "Expected: $MPLABX_PATH/mplab_platform/mplab_ipe/lib/mplab_ipe.jar"
      exit 1
    fi

    exec ${mplabxFhs}/bin/mplabx-env -c "export JAVA_HOME=$JAVA_HOME && export PATH=$JAVA_HOME/bin:\$PATH && export _JAVA_AWT_WM_NONREPARENTING=1 && $JAVA_HOME/bin/java -jar $IPE_JAR $*"
  '';
in
  pkgs.symlinkJoin {
    name = "mplab-wrappers-${mplabxVersion}";
    paths = [ideWrapper ipeWrapper ipeGuiWrapper];
    meta = with pkgs.lib; {
      description = "Wrapper scripts for MPLAB X IDE and IPE programmer";
      homepage = "https://www.microchip.com/mplab/mplab-x-ide";
      platforms = ["x86_64-linux"];
      license = licenses.mit;
    };
  }
