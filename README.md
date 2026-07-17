# Enhanced Vehicle for Farming Simulator 25

[![Validate release](https://github.com/user01010111/FS25_EnhancedVehicle/actions/workflows/validate.yml/badge.svg)](https://github.com/user01010111/FS25_EnhancedVehicle/actions/workflows/validate.yml)
[![FS25 1.20.0.0+](https://img.shields.io/badge/FS25-1.20.0.0%2B-5b8c3a)](#compatibility)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-555555)](LICENSE)

Track guidance, drivetrain controls, improved hydraulics, and a more useful
vehicle HUD for Farming Simulator 25.

[Releases](https://github.com/user01010111/FS25_EnhancedVehicle/releases) ·
[Report an issue](https://github.com/user01010111/FS25_EnhancedVehicle/issues) ·
[Original project](https://github.com/ZhooL/FS25_EnhancedVehicle) ·
[Deutsch](#deutsch)

> [!IMPORTANT]
> This is an unofficial, community-maintained fork of
> [Majo76/ZhooL's Enhanced Vehicle](https://github.com/ZhooL/FS25_EnhancedVehicle).
> It provides compatibility and stability updates while upstream maintenance is
> paused. No transfer of ownership or official endorsement is implied. Changes
> remain available for integration into the original project.

![Enhanced Vehicle HUD showing guidance and vehicle information](misc/hud_overview_en.png)

## Installation

1. Download `FS25_EnhancedVehicle.zip` from the
   [latest release](https://github.com/user01010111/FS25_EnhancedVehicle/releases).
2. Copy the ZIP file into the Farming Simulator 25 `mods` directory. Do not
   extract it.
3. Enable **Enhanced Vehicle** when loading a savegame.

Use release assets from this repository or the
[original project](https://github.com/ZhooL/FS25_EnhancedVehicle/releases).
Third-party repackaged downloads are not supported.

## Compatibility

> [!NOTE]
> Enhanced Vehicle 1.1.8.0 requires Farming Simulator 25 version 1.20.0.0 or
> newer.

### Highlights in 1.1.8.0

- More reliable dedicated-server operation and multiplayer synchronization
- Correct HUD restoration when changing vehicles
- Improved guidance direction and working-width calculation for unusual tool
  carriers
- Consistent guidance-line rendering across anti-aliasing modes
- Safer vehicle-physics and hydraulic hook compatibility
- Manifest-based release packaging and exact validated-artifact publication

## Features

- Direction snap and track guidance with configurable working width and offset
- Headland actions and selectable turnover tracks
- Parking brake, front/rear differential locks, and 2WD/4WD selection
- Grouped front/rear implement controls
- HUD data for damage, fuel, RPM, temperature, mass, odometer, trip meter,
  drivetrain state, and guidance state
- Rebindable controls through the in-game input settings

## Default controls

All controls can be changed through the in-game input settings.

<details>
<summary><strong>Show default keyboard controls</strong></summary>

| Key | Action |
| --- | --- |
| <kbd>R Ctrl</kbd> + <kbd>Num /</kbd> | Open the Enhanced Vehicle settings |
| <kbd>Num Enter</kbd> | Apply or release the parking brake |
| <kbd>R Ctrl</kbd> + <kbd>End</kbd> | Snap to the current direction or track |
| <kbd>R Ctrl</kbd> + <kbd>Home</kbd> | Reverse the guidance direction by 180° |
| <kbd>R Shift</kbd> + <kbd>Home</kbd> | Change guidance mode; hold for one second to disable guidance |
| <kbd>R Ctrl</kbd> + <kbd>Num 1</kbd> | Recalculate working width |
| <kbd>R Ctrl</kbd> + <kbd>Num 2</kbd> | Recalculate the track layout |
| <kbd>R Ctrl</kbd> + <kbd>Num 3</kbd> | Cycle guidance-line display modes |
| <kbd>R Ctrl</kbd> + <kbd>Num 4</kbd> / <kbd>Num 6</kbd> | Decrease/increase turnover tracks |
| <kbd>R Ctrl</kbd> + <kbd>Num -</kbd> / <kbd>Num +</kbd> | Move the track layout left/right |
| <kbd>R Ctrl</kbd> + <kbd>R Shift</kbd> + <kbd>Num -</kbd> / <kbd>Num +</kbd> | Move the in-track offset left/right |
| <kbd>R Shift</kbd> + <kbd>Num -</kbd> / <kbd>Num +</kbd> | Decrease/increase track width |
| <kbd>R Ctrl</kbd> + <kbd>Insert</kbd> / <kbd>Delete</kbd> | Move one track right/left |
| <kbd>R Ctrl</kbd> + <kbd>Page Up</kbd> / <kbd>Page Down</kbd> | Change direction by 1° |
| <kbd>R Shift</kbd> + <kbd>Page Up</kbd> / <kbd>Page Down</kbd> | Change direction by 45° |
| <kbd>R Ctrl</kbd> + <kbd>R Shift</kbd> + <kbd>Page Up</kbd> / <kbd>Page Down</kbd> | Change direction by 0.25° |
| <kbd>R Ctrl</kbd> + <kbd>Num *</kbd> | Cycle headland modes |
| <kbd>R Shift</kbd> + <kbd>Num /</kbd> / <kbd>Num *</kbd> | Cycle headland distances |
| <kbd>R Ctrl</kbd> + <kbd>Num 5</kbd> | Toggle odometer/trip meter; hold to reset the trip meter |
| <kbd>R Ctrl</kbd> + <kbd>Num 7</kbd> | Toggle the front differential lock |
| <kbd>R Ctrl</kbd> + <kbd>Num 8</kbd> | Toggle the rear differential lock |
| <kbd>R Ctrl</kbd> + <kbd>Num 9</kbd> | Toggle 2WD/4WD |
| <kbd>L Alt</kbd> + <kbd>1</kbd> / <kbd>2</kbd> | Raise/lower or start/stop rear implements |
| <kbd>L Alt</kbd> + <kbd>3</kbd> / <kbd>4</kbd> | Raise/lower or start/stop front implements |
| <kbd>L Alt</kbd> + <kbd>5</kbd> / <kbd>6</kbd> | Fold/unfold rear or front implements |

</details>

## Known limitations

- Fuel-consumption and engine-temperature values may be inaccurate for
  non-host players because the GIANTS Engine does not synchronize all required
  data.
- Enhanced Vehicle is not available on consoles.

## Deutsch

[Releases](https://github.com/user01010111/FS25_EnhancedVehicle/releases) ·
[Problem melden](https://github.com/user01010111/FS25_EnhancedVehicle/issues) ·
[Originalprojekt](https://github.com/ZhooL/FS25_EnhancedVehicle) ·
[English](#enhanced-vehicle-for-farming-simulator-25)

Enhanced Vehicle erweitert Fahrzeuge um einen Spurassistenten, das Einrasten in
die Fahrtrichtung, eine Feststellbremse, Differenzialsperren, wählbare
Antriebsmodi, verbesserte Hydrauliksteuerungen und ein erweitertes HUD.

> Dieser inoffizielle, von der Community gepflegte Fork stellt
> Kompatibilitäts- und Stabilitätskorrekturen bereit, solange die Pflege des
> Originalprojekts pausiert. Eine Übertragung der Eigentümerschaft oder
> offizielle Unterstützung durch den ursprünglichen Autor wird nicht
> beansprucht.

### Installation

1. `FS25_EnhancedVehicle.zip` aus dem
   [neuesten Release](https://github.com/user01010111/FS25_EnhancedVehicle/releases)
   herunterladen.
2. Die ZIP-Datei unverändert in den `mods`-Ordner von Farming Simulator 25
   kopieren.
3. **Enhanced Vehicle** beim Laden des Spielstands aktivieren.

Version 1.1.8.0 benötigt Farming Simulator 25 Version 1.20.0.0 oder neuer. Die
Tastenbelegung kann in den Spieleinstellungen geändert werden; die
Standardbelegung steht in der aufklappbaren Tabelle oben.

![Enhanced Vehicle HUD mit Spurführung und Fahrzeuginformationen](misc/hud_overview_de.png)

Bei Mitspielern, die nicht Host sind, können Kraftstoffverbrauch und
Motortemperatur wegen Einschränkungen der GIANTS Engine ungenau sein. Enhanced
Vehicle ist nicht für Konsolen verfügbar.

## Support

Report reproducible problems through
[GitHub Issues](https://github.com/user01010111/FS25_EnhancedVehicle/issues).
Include the game version, mod version, single-player or multiplayer mode, and
the relevant portion of `log.txt`.

## Build and validation

The release archive is generated from an explicit runtime-file manifest with
fixed entry ordering, timestamps, and permissions. Python 3 and Lua 5.1 are
required:

```sh
scripts/validate.sh
```

This validates the source and creates `build/FS25_EnhancedVehicle.zip`. GitHub
Actions runs the same checks for pushes and pull requests. DEFLATE output can
vary between compression runtimes even when every uncompressed payload and ZIP
metadata field is identical, so cross-toolchain byte identity is not claimed.
For community release tags, the release asset is the exact archive validated in
that tag's workflow run; the workflow also publishes its SHA-256 checksum.

## Attribution and license

Original work copyright © 2018–2025 **Majo76 (formerly ZhooL)**. The original
source is available at
[ZhooL/FS25_EnhancedVehicle](https://github.com/ZhooL/FS25_EnhancedVehicle).

This fork contains modifications made in 2026 by its community contributors;
the Git history records individual contributions. The original author remains
credited in `modDesc.xml`.

The project and this adapted version are licensed under the
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International
License](LICENSE). Redistribution must retain attribution, identify
modifications, remain non-commercial, and use the same or a compatible
ShareAlike license.
