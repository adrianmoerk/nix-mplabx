# Installation helper script for MPLAB X tools
# Downloads and runs Microchip installers in FHS environment
{
  pkgs,
  mplabxVersion,
  xc32Version,
  mplabxFhs,
}: let
  # Extract version numbers without 'v' prefix for URLs
  defaultMplabxVer = builtins.replaceStrings ["v"] [""] mplabxVersion;
  defaultXc32Ver = builtins.replaceStrings ["v"] [""] xc32Version;
in
  pkgs.writeShellScriptBin "mplab-install" ''
    set -e

    DOWNLOAD_DIR="$HOME/Downloads/microchip"
    INSTALL_DIR="/opt/microchip"

    # Default versions (can be overridden via arguments)
    XC32_VERSION="''${XC32_VERSION:-${defaultXc32Ver}}"
    MPLABX_VERSION="''${MPLABX_VERSION:-${defaultMplabxVer}}"

    # Parse command line arguments
    show_help() {
      echo "Usage: mplab-install [OPTIONS]"
      echo ""
      echo "Install Microchip MPLAB X IDE and XC32 compiler on NixOS."
      echo ""
      echo "Options:"
      echo "  --mplabx-version VERSION   MPLAB X version to install (default: $MPLABX_VERSION)"
      echo "  --xc32-version VERSION     XC32 version to install (default: $XC32_VERSION)"
      echo "  --list-versions            Show known working versions"
      echo "  --help                     Show this help message"
      echo ""
      echo "Examples:"
      echo "  mplab-install                              # Install default versions"
      echo "  mplab-install --mplabx-version 6.25        # Install MPLAB X v6.25"
      echo "  mplab-install --xc32-version 4.35          # Install XC32 v4.35"
      echo ""
      echo "Environment variables:"
      echo "  MPLABX_VERSION    Override MPLAB X version"
      echo "  XC32_VERSION      Override XC32 version"
    }

    list_versions() {
      echo "Known working versions:"
      echo ""
      echo "MPLAB X IDE:"
      echo "  6.30 (default, latest)"
      echo "  6.25"
      echo "  6.20"
      echo "  6.15"
      echo "  6.10"
      echo "  6.05"
      echo "  6.00"
      echo ""
      echo "XC32 Compiler:"
      echo "  5.10 (default, latest)"
      echo "  4.45"
      echo "  4.40"
      echo "  4.35"
      echo "  4.30"
      echo "  4.21"
      echo ""
      echo "Note: Other versions may work. Check Microchip's archive:"
      echo "  https://www.microchip.com/en-us/tools-resources/archives/mplab-ecosystem"
    }

    while [[ $# -gt 0 ]]; do
      case $1 in
        --mplabx-version)
          MPLABX_VERSION="$2"
          shift 2
          ;;
        --xc32-version)
          XC32_VERSION="$2"
          shift 2
          ;;
        --list-versions)
          list_versions
          exit 0
          ;;
        --help|-h)
          show_help
          exit 0
          ;;
        *)
          echo "Unknown option: $1"
          show_help
          exit 1
          ;;
      esac
    done

    # URLs for installers
    XC32_URL="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc32-v''${XC32_VERSION}-full-install-linux-x64-installer.run"
    MPLABX_URL="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/MPLABX-v''${MPLABX_VERSION}-linux-installer.tar"

    XC32_INSTALLER="xc32-v''${XC32_VERSION}-full-install-linux-x64-installer.run"
    MPLABX_TAR="MPLABX-v''${MPLABX_VERSION}-linux-installer.tar"

    echo "=== MPLAB X / XC32 Installation Helper ==="
    echo ""
    echo "Versions to install:"
    echo "  MPLAB X IDE: v$MPLABX_VERSION"
    echo "  XC32 Compiler: v$XC32_VERSION"
    echo ""
    echo "Installation directory: $INSTALL_DIR"
    echo ""

    # Show currently installed versions
    if [ -d "$INSTALL_DIR/mplabx" ]; then
      echo "Currently installed MPLAB X versions: $(ls $INSTALL_DIR/mplabx/ 2>/dev/null | tr '\n' ' ')"
    fi
    if [ -d "$INSTALL_DIR/xc32" ]; then
      echo "Currently installed XC32 versions: $(ls $INSTALL_DIR/xc32/ 2>/dev/null | tr '\n' ' ')"
    fi
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
    echo "1) XC32 Compiler v$XC32_VERSION only"
    echo "2) MPLAB X IDE/IPE v$MPLABX_VERSION only"
    echo "3) Both XC32 v$XC32_VERSION and MPLAB X v$MPLABX_VERSION"
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
      echo "XC32 v$XC32_VERSION installation complete!"
    }

    install_mplabx() {
      echo ""
      echo "=== Installing MPLAB X IDE/IPE v$MPLABX_VERSION ==="
      download_if_missing "$MPLABX_URL" "$MPLABX_TAR"

      echo "Extracting MPLAB X installer..."
      cd "$DOWNLOAD_DIR"
      tar -xf "$MPLABX_TAR" 2>/dev/null || true

      MPLABX_SH=$(ls MPLABX-v''${MPLABX_VERSION}*.sh 2>/dev/null | head -1)
      if [ -z "$MPLABX_SH" ]; then
        echo "Error: Could not find MPLAB X installer script for v$MPLABX_VERSION"
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
      echo "MPLAB X v$MPLABX_VERSION installation complete!"
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
      echo "XC32 versions installed: $(ls $INSTALL_DIR/xc32/ 2>/dev/null | tr '\n' ' ')"
    fi

    if [ -d "$INSTALL_DIR/mplabx" ]; then
      echo "MPLAB X versions installed: $(ls $INSTALL_DIR/mplabx/ 2>/dev/null | tr '\n' ' ')"
    fi

    echo ""
    echo "To use a specific version, set environment variables:"
    echo "  export MPLABX_VERSION=v$MPLABX_VERSION"
    echo "  export XC32_VERSION=v$XC32_VERSION"
    echo ""
    echo "Make sure your user is in the 'plugdev' group for USB programmer access."
    echo ""
  ''
