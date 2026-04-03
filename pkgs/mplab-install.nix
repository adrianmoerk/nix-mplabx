# Installation helper script for MPLAB X tools
# Downloads and runs Microchip installers in FHS environment
{
  pkgs,
  mplabxVersion,
  xc32Version,
  mplabxFhs,
}:
pkgs.writeShellScriptBin "mplab-install" ''
  set -e

  DOWNLOAD_DIR="$HOME/Downloads/microchip"
  INSTALL_DIR="/opt/microchip"

  # Available versions (update these as Microchip releases new versions)
  MPLABX_VERSIONS=("6.30" "6.25" "6.20" "6.15" "6.10" "6.05" "6.00")
  XC32_VERSIONS=("5.10" "4.45" "4.40" "4.35" "4.30" "4.21" "4.20")

  # Microchip referrer URL (required for downloads)
  REFERRER="https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide"

  echo "=== MPLAB X / XC32 Installation Helper ==="
  echo ""

  # Show currently installed versions
  if [ -d "$INSTALL_DIR/mplabx" ] && [ "$(ls -A $INSTALL_DIR/mplabx 2>/dev/null)" ]; then
    echo "Installed MPLAB X versions: $(ls $INSTALL_DIR/mplabx/ 2>/dev/null | tr '\n' ' ')"
  fi
  if [ -d "$INSTALL_DIR/xc32" ] && [ "$(ls -A $INSTALL_DIR/xc32 2>/dev/null)" ]; then
    echo "Installed XC32 versions: $(ls $INSTALL_DIR/xc32/ 2>/dev/null | tr '\n' ' ')"
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

  # Function to select version from menu
  select_version() {
    local prompt="$1"
    shift
    local versions=("$@")

    echo "" >&2
    echo "$prompt" >&2
    echo "" >&2
    local i=1
    for v in "''${versions[@]}"; do
      if [ $i -eq 1 ]; then
        echo "  $i) v$v (latest)" >&2
      else
        echo "  $i) v$v" >&2
      fi
      ((i++))
    done
    echo "" >&2

    while true; do
      read -p "Select version [1-''${#versions[@]}]: " choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "''${#versions[@]}" ]; then
        echo "''${versions[$((choice-1))]}"
        return
      fi
      echo "Invalid selection, please try again." >&2
    done
  }

  install_xc32() {
    local version="$1"

    echo ""
    echo "=== Installing XC32 Compiler v$version ==="

    local installer="xc32-v''${version}-full-install-linux-x64-installer.run"
    local url="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/$installer"

    download_if_missing "$url" "$installer"
    chmod +x "$DOWNLOAD_DIR/$installer"

    echo ""
    echo "Running XC32 installer in FHS environment..."
    echo "When prompted, install to: /opt/microchip/xc32/v$version"
    echo ""

    ${mplabxFhs}/bin/mplabx-env -c "cd $DOWNLOAD_DIR && ./$installer --mode text"

    echo ""
    echo "XC32 v$version installation complete!"
  }

  install_mplabx() {
    local version="$1"

    echo ""
    echo "=== Installing MPLAB X IDE/IPE v$version ==="

    local tarfile="MPLABX-v''${version}-linux-installer.tar"
    local url="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/$tarfile"

    download_if_missing "$url" "$tarfile"

    echo "Extracting MPLAB X installer..."
    cd "$DOWNLOAD_DIR"
    tar -xf "$tarfile" 2>/dev/null || true

    local installer=$(ls MPLABX-v''${version}*.sh 2>/dev/null | head -1)
    if [ -z "$installer" ]; then
      echo "Error: Could not find MPLAB X installer script for v$version"
      exit 1
    fi

    chmod +x "$installer"

    echo ""
    echo "Running MPLAB X installer..."
    echo "Installing to: /opt/microchip/mplabx/v$version"
    echo ""

    sudo ./$installer --nolibrarycheck -- --mode text --installdir /opt/microchip/mplabx/v$version

    echo ""
    echo "MPLAB X v$version installation complete!"
  }

  # Main menu
  echo "What would you like to install?"
  echo ""
  echo "  1) XC32 Compiler only"
  echo "  2) MPLAB X IDE/IPE only"
  echo "  3) Both XC32 and MPLAB X"
  echo "  4) Exit"
  echo ""
  read -p "Enter choice [1-4]: " main_choice

  case $main_choice in
    1)
      XC32_VERSION=$(select_version "Select XC32 version to install:" "''${XC32_VERSIONS[@]}")
      install_xc32 "$XC32_VERSION"
      ;;
    2)
      MPLABX_VERSION=$(select_version "Select MPLAB X version to install:" "''${MPLABX_VERSIONS[@]}")
      install_mplabx "$MPLABX_VERSION"
      ;;
    3)
      XC32_VERSION=$(select_version "Select XC32 version to install:" "''${XC32_VERSIONS[@]}")
      MPLABX_VERSION=$(select_version "Select MPLAB X version to install:" "''${MPLABX_VERSIONS[@]}")
      install_xc32 "$XC32_VERSION"
      install_mplabx "$MPLABX_VERSION"
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

  if [ -d "$INSTALL_DIR/xc32" ] && [ "$(ls -A $INSTALL_DIR/xc32 2>/dev/null)" ]; then
    echo "XC32 versions installed: $(ls $INSTALL_DIR/xc32/ 2>/dev/null | tr '\n' ' ')"
  fi

  if [ -d "$INSTALL_DIR/mplabx" ] && [ "$(ls -A $INSTALL_DIR/mplabx 2>/dev/null)" ]; then
    echo "MPLAB X versions installed: $(ls $INSTALL_DIR/mplabx/ 2>/dev/null | tr '\n' ' ')"
  fi

  echo ""
  echo "Wrappers will auto-detect the latest installed version."
  echo "To use a specific version, set environment variables:"
  echo "  export MPLABX_VERSION=v6.30"
  echo "  export XC32_VERSION=v5.10"
  echo ""
''
