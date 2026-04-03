# nix-mplabx

NixOS flake for Microchip MPLAB X IDE, IPE, and XC32 compiler.

Since MPLAB X and XC32 are proprietary software that cannot be redistributed, this flake provides:
- An FHS environment with all required dependencies
- Wrapper scripts for the IDE, IPE, and compiler tools
- An installation helper that downloads directly from Microchip
- A NixOS module with udev rules for USB programmers

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
    # Optional: override versions
    # mplabxVersion = "v6.30";
    # xc32Version = "v5.10";
  };

  # Add the tools to your environment
  environment.systemPackages = with inputs.nix-mplabx.packages.${pkgs.system}; [
    mplab-wrappers   # mplab-ide, mplab-ipe, mplab-ipe-gui
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
| `mplab-wrappers` | Wrapper scripts for `mplab-ide`, `mplab-ipe`, `mplab-ipe-gui` |
| `xc32-wrappers` | Wrapper scripts for XC32 compiler tools |
| `mplab-install` | Interactive installer that downloads from Microchip |
| `mplabx-fhs` | FHS environment (used internally by wrappers) |
| `default` | All of the above bundled together |

## Commands

After installation:

```bash
# Start MPLAB X IDE
mplab-ide

# Start IPE (GUI mode)
mplab-ipe-gui

# IPE command-line (for scripting/automation)
mplab-ipe -?

# XC32 compiler
xc32-gcc --version
```

## Custom Versions

To use different versions of MPLAB X or XC32:

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

## Installation Directory

Tools are installed to `/opt/microchip/`:
- `/opt/microchip/mplabx/v6.30/` - MPLAB X IDE
- `/opt/microchip/xc32/v5.10/` - XC32 compiler

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

The wrappers use MPLAB's bundled Java 8. If you see Java errors, ensure the bundled JRE path is correct for your MPLAB X version.

### IDE crashes on startup

Try running in FHS environment directly to see errors:
```bash
mplabx-env
cd /opt/microchip/mplabx/v6.30/mplab_platform/bin
./mplab_ide
```

## License

The Nix packaging code is MIT licensed. MPLAB X IDE and XC32 compiler are proprietary Microchip software - see [Microchip's license](https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide).
