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
  XC32_VERSIONS=("5.10" "5.00" "4.60" "4.50" "4.45" "4.40" "4.35" "4.30" "4.21" "4.20")
  XC8_VERSIONS=("3.10" "3.00" "2.50" "2.46" "2.45" "2.41" "2.40")
  XC16_VERSIONS=("2.10" "2.00")
  XCDSC_VERSIONS=("3.31" "3.30" "3.21" "3.20" "3.10" "3.00")

  # Microchip referrer URL (required for downloads)
  REFERRER="https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide"

  echo "=== MPLAB X / XC Compiler Installation Helper ==="
  echo ""

  # Print installed versions of each tool
  show_installed() {
    local prefix="$1"
    local tool
    for tool in mplabx xc8 xc16 xc-dsc xc32; do
      if [ -d "$INSTALL_DIR/$tool" ] && [ "$(ls -A $INSTALL_DIR/$tool 2>/dev/null)" ]; then
        echo "$prefix $tool: $(ls $INSTALL_DIR/$tool/ 2>/dev/null | tr '\n' ' ')"
      fi
    done
  }

  show_installed "Installed"
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

  # Install an XC compiler
  # Args: <tool dir/file prefix> <display name> <version> <platform suffix>
  install_compiler() {
    local tool="$1"
    local name="$2"
    local version="$3"
    local platform="$4"
    local prefix="$INSTALL_DIR/$tool/v$version"

    echo ""
    echo "=== Installing $name Compiler v$version ==="

    local installer="''${tool}-v''${version}-full-install-''${platform}-installer.run"
    local url="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/$installer"

    download_if_missing "$url" "$installer"
    chmod +x "$DOWNLOAD_DIR/$installer"

    echo ""
    echo "Running $name installer in FHS environment..."
    echo "Installing to: $prefix"
    echo ""

    ${mplabxFhs}/bin/mplabx-env -c "cd $DOWNLOAD_DIR && ./$installer --mode text --prefix $prefix"

    echo ""
    echo "$name v$version installation complete!"
  }

  install_xc32() { install_compiler xc32 XC32 "$1" linux-x64; }
  install_xc8() { install_compiler xc8 XC8 "$1" linux-x64; }
  install_xc16() { install_compiler xc16 XC16 "$1" linux64; }
  install_xcdsc() { install_compiler xc-dsc XC-DSC "$1" linux64; }

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
  echo "  1) XC32 Compiler (PIC32 / SAM)"
  echo "  2) XC8 Compiler (PIC10/12/16/18 / AVR)"
  echo "  3) XC16 Compiler (PIC24 / dsPIC)"
  echo "  4) XC-DSC Compiler (dsPIC DSC)"
  echo "  5) MPLAB X IDE/IPE"
  echo "  6) Both XC32 and MPLAB X"
  echo "  7) Exit"
  echo ""
  read -p "Enter choice [1-7]: " main_choice

  case $main_choice in
    1)
      XC32_VERSION=$(select_version "Select XC32 version to install:" "''${XC32_VERSIONS[@]}")
      install_xc32 "$XC32_VERSION"
      ;;
    2)
      XC8_VERSION=$(select_version "Select XC8 version to install:" "''${XC8_VERSIONS[@]}")
      install_xc8 "$XC8_VERSION"
      ;;
    3)
      XC16_VERSION=$(select_version "Select XC16 version to install:" "''${XC16_VERSIONS[@]}")
      install_xc16 "$XC16_VERSION"
      ;;
    4)
      XCDSC_VERSION=$(select_version "Select XC-DSC version to install:" "''${XCDSC_VERSIONS[@]}")
      install_xcdsc "$XCDSC_VERSION"
      ;;
    5)
      MPLABX_VERSION=$(select_version "Select MPLAB X version to install:" "''${MPLABX_VERSIONS[@]}")
      install_mplabx "$MPLABX_VERSION"
      ;;
    6)
      XC32_VERSION=$(select_version "Select XC32 version to install:" "''${XC32_VERSIONS[@]}")
      MPLABX_VERSION=$(select_version "Select MPLAB X version to install:" "''${MPLABX_VERSIONS[@]}")
      install_xc32 "$XC32_VERSION"
      install_mplabx "$MPLABX_VERSION"
      ;;
    7)
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

  show_installed "Installed"

  echo ""
  echo "Wrappers will auto-detect the latest installed version."
  echo "To use a specific version, set environment variables:"
  echo "  export MPLABX_VERSION=v6.30"
  echo "  export XC32_VERSION=v5.10"
  echo ""
  echo "XC8/XC16/XC-DSC have no command-line wrappers yet. MPLAB X picks them up"
  echo "from $INSTALL_DIR, or add them under Tools > Options > Embedded > Build Tools."
  echo ""
''
