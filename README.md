# nix-mplabx

NixOS flake for Microchip MPLAB X IDE, IPE, and XC32 compiler.

Since MPLAB X and XC32 are proprietary software that cannot be redistributed, this flake provides:
- An FHS environment with all required dependencies
- Wrapper scripts for the IDE, IPE, and compiler tools
- An installation helper that downloads directly from Microchip
- A NixOS module with udev rules for USB programmers
- Support for multiple versions installed side-by-side

## Supported Hardware

- PICkit 4 / PICkit 5
- MPLAB SNAP
- ICD 4 / ICD 5
- REAL ICE

## Quick Start

### 1. Add to your flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-mplabx.url = "github:adrianmoerk/nix-mplabx";
  };
}
```

### 2. Add packages and module to your configuration

```nix
{ inputs, pkgs, ... }: {
  imports = [
    inputs.nix-mplabx.nixosModules.mplabx
  ];

  # Enable MPLAB support with udev rules
  programs.mplabx = {
    enable = true;
    users = [ "yourusername" ];  # Users with USB programmer access
  };

  # Add the tools to your environment
  environment.systemPackages = with inputs.nix-mplabx.packages.${pkgs.system}; [
    mplab-wrappers   # mplab-ide, mplab-ipe, mplab-ipe-gui, mplab-versions
    xc32-wrappers    # xc32-gcc, xc32-g++, etc.
    mplab-install    # Installation helper
  ];
}
```

### 3. Rebuild and install

```bash
sudo nixos-rebuild switch

# Run the installer (downloads from Microchip)
mplab-install
```

## Available Packages

| Package | Description |
|---------|-------------|
| `mplab-wrappers` | Wrapper scripts for `mplab-ide`, `mplab-ipe`, `mplab-ipe-gui`, `mplab-versions` |
| `xc32-wrappers` | Wrapper scripts for XC32 compiler tools |
| `mplab-install` | Interactive installer that downloads from Microchip |
| `mplabx-fhs` | FHS environment (used internally by wrappers) |
| `default` | All of the above bundled together |

## Commands

After installation:

```bash
# Start MPLAB X IDE (uses latest installed version)
mplab-ide

# Start IPE (GUI mode)
mplab-ipe-gui

# IPE command-line (for scripting/automation)
mplab-ipe -?

# XC32 compiler
xc32-gcc --version

# Show installed versions
mplab-versions
```

## Version Management

### Installing Versions

The installer provides an interactive menu to select versions:

```bash
mplab-install
```

```
=== MPLAB X / XC32 Installation Helper ===

What would you like to install?

  1) XC32 Compiler only
  2) MPLAB X IDE/IPE only
  3) Both XC32 and MPLAB X
  4) Exit

Enter choice [1-4]: 3

Select XC32 version to install:

  1) v5.10 (latest)
  2) v4.45
  3) v4.40
  ...

Select version [1-7]: 1
```

### Using Specific Versions

The wrappers automatically detect the latest installed version. To use a specific version:

```bash
# Set environment variables
export MPLABX_VERSION=v6.25
export XC32_VERSION=v4.35

# Or inline
MPLABX_VERSION=v6.25 mplab-ide
XC32_VERSION=v4.35 xc32-gcc --version
```

### Multiple Versions Side-by-Side

You can install multiple versions. They are stored in:
- `/opt/microchip/mplabx/v6.30/`
- `/opt/microchip/mplabx/v6.25/`
- `/opt/microchip/xc32/v5.10/`
- `/opt/microchip/xc32/v4.35/`

## Custom Versions in Nix Config

To set default versions in your NixOS configuration:

```nix
{ inputs, pkgs, ... }:
let
  mplabx = inputs.nix-mplabx.lib.${pkgs.system};
in {
  environment.systemPackages = [
    (mplabx.mkMplabWrappers { mplabxVersion = "v6.25"; })
    (mplabx.mkXc32Wrappers { xc32Version = "v4.35"; })
    (mplabx.mkMplabInstall {
      mplabxVersion = "v6.25";
      xc32Version = "v4.35";
    })
  ];
}
```

## NixOS Module Options

```nix
programs.mplabx = {
  enable = true;                    # Enable udev rules
  users = [ "alice" "bob" ];        # Users with USB programmer access
  mplabxVersion = "v6.30";          # Default MPLAB X version (for reference)
  xc32Version = "v5.10";            # Default XC32 version (for reference)
};
```

## Troubleshooting

### USB programmer not detected

1. Make sure your user is in the `plugdev` group:
   ```bash
   groups  # Should show plugdev
   ```

2. If not, add via the module or manually:
   ```bash
   sudo usermod -aG plugdev $USER
   # Log out and back in
   ```

3. Check udev rules are loaded:
   ```bash
   lsusb  # Find your programmer
   ls -la /dev/bus/usb/...  # Check permissions
   ```

### Java errors in IDE

The wrappers use MPLAB's bundled Java 8. If you see Java errors, ensure the bundled JRE exists in the MPLAB X installation directory.

### IDE crashes on startup

Try running in FHS environment directly to see errors:
```bash
mplabx-env
cd /opt/microchip/mplabx/v6.30/mplab_platform/bin
./mplab_ide
```

### Wrong version being used

Check which versions are installed and selected:
```bash
mplab-versions
echo $MPLABX_VERSION
echo $XC32_VERSION
```

## License

The Nix packaging code is MIT licensed. MPLAB X IDE and XC32 compiler are proprietary Microchip software - see [Microchip's license](https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide).
