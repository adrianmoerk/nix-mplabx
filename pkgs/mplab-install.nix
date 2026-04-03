# Installation helper script for MPLAB X tools
# Downloads and runs Microchip installers in FHS environment
{
  pkgs,
  mplabxVersion,
  xc32Version,
  mplabxFhs,
}: let
  # Extract version numbers without 'v' prefix for URLs
  mplabxVer = builtins.replaceStrings ["v"] [""] mplabxVersion;
  xc32Ver = builtins.replaceStrings ["v"] [""] xc32Version;
in
  pkgs.writeShellScriptBin "mplab-install" ''
    set -e

    DOWNLOAD_DIR="$HOME/Downloads/microchip"
    INSTALL_DIR="/opt/microchip"

    # Version info
    XC32_VERSION="${xc32Ver}"
    MPLABX_VERSION="${mplabxVer}"

    # URLs for installers
    XC32_URL="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc32-v''${XC32_VERSION}-full-install-linux-x64-installer.run"
    MPLABX_URL="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/MPLABX-v''${MPLABX_VERSION}-linux-installer.tar"

    XC32_INSTALLER="xc32-v''${XC32_VERSION}-full-install-linux-x64-installer.run"
    MPLABX_TAR="MPLABX-v''${MPLABX_VERSION}-linux-installer.tar"

    echo "=== MPLAB X / XC32 Installation Helper ==="
    echo ""
    echo "Versions:"
    echo "  MPLAB X IDE: v$MPLABX_VERSION"
    echo "  XC32 Compiler: v$XC32_VERSION"
    echo ""
    echo "Installation directory: $INSTALL_DIR"
    echo ""

    # Create directories
    mkdir -p "$DOWNLOAD_DIR"

    # Check if /opt/microchip exists and is writable
    if [ ! -d "$INSTALL_DIR" ]; then
      echo "Creating $INSTALL_DIR (requires sudo)..."
      sudo mkdir -p "$INSTALL_DIR"
      sudo chown $USER:users "$INSTALL_DIR"
    fi

    # Microchip referrer URL (required for downloads)
    REFERRER="https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide"

    # Function to download if not present
    download_if_missing() {
      local url="$1"
      local file="$2"

      if [ ! -f "$DOWNLOAD_DIR/$file" ]; then
        echo "Downloading $file..."
        ${pkgs.curl}/bin/curl -L -e "$REFERRER" -o "$DOWNLOAD_DIR/$file" "$url"
      else
        echo "$file already downloaded"
      fi
    }

    # Menu
    echo "What would you like to install?"
    echo "1) XC32 Compiler only"
    echo "2) MPLAB X IDE/IPE only"
    echo "3) Both XC32 and MPLAB X"
    echo "4) Exit"
    echo ""
    read -p "Enter choice [1-4]: " choice

    install_xc32() {
      echo ""
      echo "=== Installing XC32 Compiler v$XC32_VERSION ==="
      download_if_missing "$XC32_URL" "$XC32_INSTALLER"

      chmod +x "$DOWNLOAD_DIR/$XC32_INSTALLER"

      echo ""
      echo "Running XC32 installer in FHS environment..."
      echo "When prompted, install to: /opt/microchip/xc32/v$XC32_VERSION"
      echo ""

      ${mplabxFhs}/bin/mplabx-env -c "cd $DOWNLOAD_DIR && ./$XC32_INSTALLER --mode text"

      echo ""
      echo "XC32 installation complete!"
    }

    install_mplabx() {
      echo ""
      echo "=== Installing MPLAB X IDE/IPE v$MPLABX_VERSION ==="
      download_if_missing "$MPLABX_URL" "$MPLABX_TAR"

      echo "Extracting MPLAB X installer..."
      cd "$DOWNLOAD_DIR"
      tar -xf "$MPLABX_TAR" 2>/dev/null || true

      MPLABX_SH=$(ls MPLABX-v*.sh 2>/dev/null | head -1)
      if [ -z "$MPLABX_SH" ]; then
        echo "Error: Could not find MPLAB X installer script"
        exit 1
      fi

      chmod +x "$MPLABX_SH"

      echo ""
      echo "Running MPLAB X installer..."
      echo "Installing to: /opt/microchip/mplabx/v$MPLABX_VERSION"
      echo ""

      cd "$DOWNLOAD_DIR"
      sudo ./$MPLABX_SH --nolibrarycheck -- --mode text --installdir /opt/microchip/mplabx/v$MPLABX_VERSION

      echo ""
      echo "MPLAB X installation complete!"
    }

    case $choice in
      1)
        install_xc32
        ;;
      2)
        install_mplabx
        ;;
      3)
        install_xc32
        install_mplabx
        ;;
      4)
        echo "Exiting."
        exit 0
        ;;
      *)
        echo "Invalid choice"
        exit 1
        ;;
    esac

    echo ""
    echo "=== Installation Summary ==="
    echo ""

    if [ -d "$INSTALL_DIR/xc32" ]; then
      echo "XC32 installed: $(ls $INSTALL_DIR/xc32/ 2>/dev/null || echo 'none')"
      echo "  Test with: xc32-gcc --version"
    fi

    if [ -d "$INSTALL_DIR/mplabx" ]; then
      echo "MPLAB X installed: $(ls $INSTALL_DIR/mplabx/ 2>/dev/null || echo 'none')"
      echo "  Test with: mplab-ipe -?"
      echo "  Start IDE: mplab-ide"
    fi

    echo ""
    echo "Make sure your user is in the 'plugdev' group for USB programmer access."
    echo "If using the NixOS module, this is handled automatically."
    echo ""
  ''
