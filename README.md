# WoWAstralKeys

Export a table of your World of Warcraft characters' Mythic Keystones from Astral Keys addon.

## Description

The `WoWAstralKeys` script will check your World of Warcraft install folder and read the AstralKeys SavedVariables files for all accounts and then output them to the screen.

You can also use options to output the data to a CSV or a JSON file, or sanitize specific features such as removing server name, or hiding the names of the characters.

Use this script to dump all your keys so you can easily share with your friends!

## Installation

No installation is required.  Just clone this repository.

## Requirements

This script should be able to run in either PowerShell Desktop 3.0 or newer, or PowerShell Core.  It has been tested on Desktop 5.1.19041.1320 and Core 7.2.1.

Currently, this requires [Lua](https://www.lua.org/) to be installed.  If it is in your path, it will be found this script.  If not, it will ask you where the [Lua](https://www.lua.org/) executable is located.

You can download [Lua](https://www.lua.org/) from here: http://luabinaries.sourceforge.net/download.html

You also must use the Astral Keys addon in order to keep track of your mythic keys in-game.  The SavedVariables files get updated upon character logoff.  As long as you exit to the character selection screen, your SVs should be updated.

Get the Astral Keys addon! ([CurseForge](https://www.curseforge.com/wow/addons/astral-keys) &middot; [Github](https://github.com/astralguild/AstralKeys))

## Usage

```powershell
PS> .\WoWAstralKeys.ps1 | Format-Table

Name                   Faction  Class        Dungeon            Level WeeklyBest
----                   -------  -----        -------            ----- ----------
Character1-Server1     Alliance Demon Hunter De Other Side         17         15
Character2-Server1     Alliance Paladin      Halls of Atonement    16         15
Character3-Server1     Alliance Warrior      No key                 0          0
Character4-Server2     Alliance Monk         Plaguefall            10          7
Character5-Server2     Alliance Hunter       Theater of Pain       15          0
Character6-Server3     Horde    Mage         Theater of Pain       10          0
Character7-Server3     Horde    Paladin      No key                 0          0
```

```powershell
PS> .\WoWAstralKeys.ps1 -Faction Horde | Format-Table

Name                   Faction  Class        Dungeon            Level WeeklyBest
----                   -------  -----        -------            ----- ----------
Character6-Server3     Horde    Mage         Theater of Pain       10          0
Character7-Server3     Horde    Paladin      No key                 0          0
```

```powershell
PS> .\WoWAstralKeys.ps1 -FilterNoKeys | Format-Table

Name                   Faction  Class        Dungeon            Level WeeklyBest
----                   -------  -----        -------            ----- ----------
Character1-Server1     Alliance Demon Hunter De Other Side         17         15
Character2-Server1     Alliance Paladin      Halls of Atonement    16         15
Character4-Server2     Alliance Monk         Plaguefall            10          7
Character5-Server2     Alliance Hunter       Theater of Pain       15          0
Character6-Server3     Horde    Mage         Theater of Pain       10          0
```

```powershell
PS> .\WoWAstralKeys.ps1 -NoServer | Format-Table

Name           Faction  Class        Dungeon            Level WeeklyBest
----           -------  -----        -------            ----- ----------
Character1     Alliance Demon Hunter De Other Side         17         15
Character2     Alliance Paladin      Halls of Atonement    16         15
Character3     Alliance Warrior      No key                 0          0
Character4     Alliance Monk         Plaguefall            10          7
Character5     Alliance Hunter       Theater of Pain       15          0
Character6     Horde    Mage         Theater of Pain       10          0
Character7     Horde    Paladin      No key                 0          0
```

```powershell
PS> .\WoWAstralKeys.ps1 -Anonymous | Format-Table

Faction  Class        Dungeon            Level WeeklyBest
-------  -----        -------            ----- ----------
Alliance Demon Hunter De Other Side         17         15
Alliance Paladin      Halls of Atonement    16         15
Alliance Warrior      No key                 0          0
Alliance Monk         Plaguefall            10          7
Alliance Hunter       Theater of Pain       15          0
Horde    Mage         Theater of Pain       10          0
Horde    Paladin      No key                 0          0
```

## Roadmap Items

* An option to filter on specific WoW accounts (currently reports all accounts)

## Author

[RavenDT](https://github.com/RavenDT)

## License

[MIT License](LICENSE)

## External Libraries

Simple JSON Encode/Decode in Pure Lua — Version 20211016.28 (http://regex.info/blog/lua/json)

Copyright 2010-2017 Jeffrey Friedl.  All rights reserved.  [Creative Commons CC-BY "Attribution" License](http://creativecommons.org/licenses/by/3.0/deed.en_US).
