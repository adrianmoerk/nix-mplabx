# FHS environment for running MPLAB X tools (XC32, IPE, IDE)
# Provides all dependencies needed by Microchip's proprietary tools
{pkgs, ...}:
pkgs.buildFHSEnv {
  name = "mplabx-env";

  targetPkgs = pkgs:
    with pkgs; [
      # Java runtime (required for IPE and IDE)
      jdk11

      # Core libraries
      glibc
      gcc
      binutils
      gnumake
      git
      cacert
      curl
      unzip
      zip
      gnutar
      gzip
      xdg-utils
      procps
      which
      zlib
      stdenv.cc.cc.lib

      # USB support (for PICkit4/5)
      libusb1
      udev

      # GUI libraries (for IPE GUI mode)
      gtk3
      glib
      cairo
      pango
      gdk-pixbuf
      atk
      dbus
      fontconfig
      freetype

      # X11 libraries
      libx11
      libxrender
      libxtst
      libxext
      libxi
      libxcursor
      libxrandr
      libxfixes
      libxinerama
      libxcomposite
      libxdamage

      # Additional dependencies
      alsa-lib
      cups
      libdrm
      mesa
      nspr
      nss

      # 32-bit libraries (some tools need these)
      pkgsi686Linux.glibc
      pkgsi686Linux.gcc
      pkgsi686Linux.zlib
    ];

  # Environment variables for Java AWT
  # Don't set JAVA_HOME - let MPLAB use its bundled Java 8
  profile = ''
    export _JAVA_AWT_WM_NONREPARENTING=1
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  runScript = "bash";

  meta = with pkgs.lib; {
    description = "FHS environment for running MPLAB X IDE and tools";
    platforms = ["x86_64-linux"];
    license = licenses.mit;
  };
}
