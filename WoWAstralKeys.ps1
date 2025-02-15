#Requires -Version 5

<#
.SYNOPSIS
    Read the AstralKeys SavedVariables from your WoW folder and output to screen or to a file.
.DESCRIPTION
    The `WoWAstralKeys` script will check your World of Warcraft install folder and read the AstralKeys SavedVariables files for all accounts and then output them to the screen.

    You can also use options to remove server names or hiding the names of the characters.

    Use this script to dump all your keys so you can easily share with your friends!
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Version:            v2.2.1
    Author(s):          RavenDT (https://github.com/RavenDT)
    Maintainer(s):      RavenDT (https://github.com/RavenDT)
    Website:            https://github.com/RavenDT/WoWAstralKeys
    Modified Date:      2025-02-15
    Purpose/Change:     - Update for TWW Season 1 dungeons
    License:            MIT License
.EXAMPLE
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
.EXAMPLE
    PS> .\WoWAstralKeys.ps1 -Faction Horde | Format-Table

    Name                   Faction  Class        Dungeon            Level WeeklyBest
    ----                   -------  -----        -------            ----- ----------
    Character6-Server3     Horde    Mage         Theater of Pain       10          0
    Character7-Server3     Horde    Paladin      No key                 0          0
.EXAMPLE
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
.EXAMPLE
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
#>

#----------------------------------------------[Script Parameters]-------------------------------------------------

[CmdletBinding()]
Param (
    # Remove server names from character names.
    [Parameter()]
    [Switch]$NoServer,

    # Remove character names from output.
    [Parameter()]
    [Switch]$Anonymous
)

#------------------------------------------------[Declarations]----------------------------------------------------

"Declarations" | Write-Debug

Class WoWAstralKeys {
    [String] $Name
    hidden [Bool] $Faction_
    hidden [String] $Class_
    hidden [UInt16] $Dungeon_
    [UInt16] $Level
    [UInt16] $WeeklyBest
    hidden [UInt32] $Timestamp

    static hidden $_FACTION_LOOKUP = @{
        '0' = 'Alliance'
        '1' = 'Horde'
    }

    static hidden $_CLASS_LOOKUP = @{
        UNKNOWN     = "Unknown"
        DEATHKNIGHT = "Death Knight"
        DEMONHUNTER = "Demon Hunter"
        DRUID       = "Druid"
        EVOKER      = "Evoker"
        HUNTER      = "Hunter"
        MAGE        = "Mage"
        MONK        = "Monk"
        PALADIN     = "Paladin"
        PRIEST      = "Priest"
        ROGUE       = "Rogue"
        SHAMAN      = "Shaman"
        WARLOCK     = "Warlock"
        WARRIOR     = "Warrior"
    }

    static hidden $_DUNGEON_LOOKUP = @{
        '65535' = "No key"
        '2'     = "Temple of the Jade Serpent"
        '165'   = "Shadowmoon Burial Grounds"
        '168'   = "The Everbloom"
        '198'   = "Darkheart Thicket"
        '199'   = "Black Rock Hold"
        '200'   = "Halls of Valor"
        '206'   = "Neltharion's Lair"
        '210'   = "Court of Stars"
        '244'   = "Atal'Dazar"
        '245'   = "Freehold"
        '248'   = "Waycrest Manor"
        '251'   = "The Underrot"
        '353'   = "Siege of Boralus"
        '375'   = "Mists of Tirna Scithe"
        '376'   = "The Necrotic Wake"
        '377'   = "De Other Side"
        '378'   = "Halls of Atonement"
        '379'   = "Plaguefall"
        '380'   = "Sanguine Depths"
        '381'   = "Spires of Ascension"
        '382'   = "Theater of Pain"
        '391'   = "Streets of Wonder"
        '392'   = "So'leah's Gambit"
        '399'   = "Ruby Life Pools"
        '400'   = "Nokhud Offensive"
        '401'   = "The Azure Vault"
        '402'   = "Algeth'ar Academy"
        '403'   = "Uldaman: Legacy of Tyr"
        '404'   = "Neltharus"
        '405'   = "Brackenhide Hollow"
        '406'   = "Halls of Infusion"
        '438'   = "Vortex Pinnacle"
        '456'   = "Throne of the Tides"
        '463'   = "DOTI: Galakrond's Fall"
        '464'   = "DOTI: Murozond's Rise"
        '501'   = "The Stonevault"
        '502'   = "City of Threads"
        '503'   = "Ara-Kara, City of Echoes"
        '505'   = "The Dawnbreaker"
        '507'   = "Grim Batol"
    }

    hidden _Add_ScriptProperties() {
        [OutputType([Void])]

        $this |
            Add-Member -MemberType 'ScriptProperty' -Name 'Faction' -Value {
                if ($this.Faction_) { "Horde" } else { "Alliance" }
            } -SecondValue {
                Param ($Arg)
                if ($Arg -as [Bool]) {
                    $this.Faction_ = $Arg
                } elseif ($Arg -like 'Alliance') {
                    $this.Faction_ = $False
                } elseif ($Arg -like 'Horde') {
                    $this.Faction_ = $True
                } else {
                    throw "$Arg is not a valid faction."
                }
            }
        $this |
            Add-Member -MemberType 'ScriptProperty' -Name 'Class' -Value {
                [WoWAstralKeys]::_CLASS_LOOKUP[$this.Class_]
            } -SecondValue {
                Param ([String]$Class)
                if ($Class -in [WoWAstralKeys]::_CLASS_LOOKUP.Keys) {
                    $this.Class_ = $Class
                } elseif ($Class -in [WoWAstralKeys]::_CLASS_LOOKUP.Values) {
                    $this.Class_ = [WoWAstralKeys]::_CLASS_LOOKUP.GetEnumerator().
                    Where({ $_.Value -like $Class }).Name
                } else {
                    throw "$Class is not a valid class."
                }
            }

        $this |
            Add-Member -MemberType 'ScriptProperty' -Name 'Dungeon' -Value {
                [WoWAstralKeys]::_DUNGEON_LOOKUP[([String]$this.Dungeon_)]
            } -SecondValue {
                Param ($Dungeon)
                if ($Dungeon -as [UInt16] -and $Dungeon -in [WoWAstralKeys]::_DUNGEON_LOOKUP.Keys) {
                    $this.Dungeon_ = $Dungeon
                } elseif ($Dungeon -in [WoWAstralKeys]::_DUNGEON_LOOKUP.Values) {
                    $this.Dungeon_ = [WoWAstralKeys]::_DUNGEON_LOOKUP.GetEnumerator().
                    Where({ $_.Value -like $Dungeon }).Name
                } else {
                    throw "$Dungeon is an unknown Dungeon."
                }
            }
    }

    WoWAstralKeys() {
        $this._Add_ScriptProperties()
    }

    WoWAstralKeys(
        [String]$Name,
        [Bool]$Faction,
        [String]$Class,
        [UInt16]$Dungeon,
        [UInt16]$Level,
        [UInt16]$WeeklyBest
    ) {
        $this._Add_ScriptProperties()

        $this.Name = $Name
        $this.Faction_ = $Faction
        $this.Class_ = $Class
        $this.Dungeon_ = $Dungeon
        $this.Level = $Level
        $this.WeeklyBest = $WeeklyBest
    }

    [String] ToString() {
        return (
            (
                "@{Name=`"$($this.Name)`"",
                "Faction=`"$($this.Faction)`"",
                "Class=`"$($this.Class)`"",
                "Dungeon=`"$($this.Dungeon)`"",
                "Level=`"$($this.Level)`"",
                "WeeklyBest=`"$($this.WeeklyBest)`""
            ) -join "; "
        ) + "}"
    }
}

$OutputProperties = @{
    Property = [System.Collections.ArrayList]@("Name","Faction","Class","Dungeon","Level","WeeklyBest")
}

#-----------------------------------------------[Initializations]--------------------------------------------------

"Initializations" | Write-Debug

# Load stored configuration file
$ConfigFilePath = "~" | Join-Path -ChildPath ".wakconfig" | Resolve-Path
if ( -not (Test-Path -Path $ConfigFilePath) ) {
    "Configuration file was not found." | Write-Verbose
    $Config = [PSCustomObject]@{
        LuaPath = ""
        WoWPath = ""
    }
    $ConfigHash = $null
} else {
    "Found configuration file!" | Write-Verbose
    $Config = Get-Content -Path $ConfigFilePath | ConvertFrom-Json
    $ConfigHash = (Get-FileHash -Algorithm SHA256 -Path $ConfigFilePath).Hash
}
<#
    Stored config should have:
    - LuaPath - The location of the Lua command
    - WoWPath - The location of the WoW install (default: 'C:\World of Warcraft')
#>
$ConfigChanged = $false

# Make sure we know where the 'lua' command is
if ( -not $Config.LuaPath -or -not (Test-Path $Config.LuaPath) ) {
    # Check path before asking the user
    $Lua = Get-Command "lua.exe"
    #"`$Lua is $Lua" | Out-Host
    if ($Config.PSObject.Properties.Name -notcontains 'LuaPath') {
        $Config | Add-Member -NotePropertyName 'LuaPath' -NotePropertyValue ''
        $ConfigChanged = $true
    }
    $Config.LuaPath = if ($Lua) { $Lua.Path } else {
        (
            Resolve-Path -Path (
                Read-Host @EASC -Prompt (
                    @(
                        "Unable to locate 'lua' command in path.",
                        "Please enter the location of the 'lua' executable"
                    ) -join "`n"
                )
            )
        ).Path
    }
    $ConfigChanged = $true
} else {
    $Lua = $Config.LuaPath
}

@"
`$Config = {0}
`$ConfigChanged = {1}
`$Lua = {2}
"@ -f $Config,$ConfigChanged,$Lua | Write-Debug

if (!$Lua) {
    throw "'Lua' command was not found; exiting."
    exit
}

# Make sure we know where WoW is installed
if ( -not $Config.WoWPath -or -not (Test-Path $Config.WoWPath) ) {
    # Check default install location(s) before asking the user
    if ($Config.PSObject.Properties.Name -notcontains 'WoWPath') {
        $Config | Add-Member -NotePropertyName 'WoWPath' -NotePropertyValue ''
        $ConfigChanged = $true
    }
    if (
        (
            $PSVersionTable.PSEdition -eq 'Desktop' -or
            (
                $PSVersionTable.PSEdition -eq 'Core' -and
                $IsWindows
            )
        ) -and
        (Resolve-Path @EASC -Path 'C:\World of Warcraft')
    ) {
        $Config.WoWPath = 'C:\World of Warcraft'
        $ConfigChanged = $true
    } else {
        # Ask the user where WoW is installed
        $Config.WoWPath = (
            Resolve-Path -Path (
                Read-Host @EASC -Prompt (
                    @(
                        "Unable to locate WoW installation.",
                        "Please enter the location of your WoW install"
                    ) -join "`n"
                )
            )
        ).Path
        $ConfigChanged = $true
    }
}

$MyKeyData = @{}

#--------------------------------------------------[Functions]-----------------------------------------------------

"Functions" | Write-Debug

function Invoke-WAKCharacterExtraction {
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]$InputObject,

        [Parameter(Mandatory)]
        [Hashtable]$Hashtable
    )

    Process {
        foreach ($Item in $InputObject.AstralCharacters) {
            if ($Item.unit -notin $Hashtable.Keys) { $Hashtable[$Item.unit] = @{} }
            $Hashtable[$Item.unit] = [WoWAstralKeys]::new(
                $Item.unit,         # Name
                $Item.faction,      # Faction
                $Item.class,        # Class
                65535,              # Dungeon
                0,                  # Level of Key
                $Item.weekly_best   # Weekly Best
            )
        }
    }
}

function Invoke-WAKKeystoneExtraction {
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]$InputObject,

        [Parameter(Mandatory)]
        [Hashtable]$Hashtable
    )

    Process {
        $ObjectFiltered = ($InputObject.AstralKeys).Where({ $_.unit -in $Hashtable.Keys })
        foreach ($Item in $ObjectFiltered) {
            if ($Hashtable[$Item.unit].Count -eq 0) {
                $PropertiesToSet = @{
                    Name = $Item.unit
                    Class = 'Unknown'
                    Faction = 0
                    Dungeon = $Item.dungeon_id
                    Level = $Item.key_level
                    WeeklyBest = $Item.weekly_best
                    TimeStamp = $Item.time_stamp
                }
            } elseif ($Hashtable[$Item.unit].Timestamp -lt $Item.time_stamp) {
                $PropertiesToSet = @{
                    Dungeon = $Item.dungeon_id
                    Level = $Item.key_level
                    WeeklyBest = $Item.weekly_best
                    TimeStamp = $Item.time_stamp
                }
            } else {
                continue
            }

            $PropertiesToSet.GetEnumerator().ForEach({
                "Setting '{0}'.'{1}' to '{2}'" -f $Item.unit,$_.Key,$_.Value | Write-Verbose
                $Hashtable[$Item.unit].$($_.Key) = $_.Value
            })
        }
    }
}

#--------------------------------------------------[Execution]-----------------------------------------------------

"Execution" | Write-Debug

$AKTargetPath = $Config.WoWPath |
    Join-Path -ChildPath "_retail_" |
    Join-Path -ChildPath "WTF" |
    Join-Path -ChildPath "Account" |
    Join-Path -ChildPath "*" |
    Join-Path -ChildPath "SavedVariables" |
    Join-Path -ChildPath "AstralKeys.lua"
$AKTargetFiles = Get-ChildItem -Path $AKTargetPath -Recurse
$AKTargetPath | Write-Debug
$AKTargetFiles | Write-Debug

# Do the work
foreach ($File in $AKTargetFiles) {
    $ImportJson = & $Lua "$PWD\AK_Lua_to_Json.lua" "$File"
    $PWD | Write-Debug
    $ImportJson | Write-Debug
    $ImportObject = $ImportJson | ConvertFrom-Json
    $ImportObject | Invoke-WAKCharacterExtraction -Hashtable $MyKeyData
    $ImportObject | Invoke-WAKKeystoneExtraction -Hashtable $MyKeyData
}

# Once we ensure uniqueness, let's strip off the keys and only keep the values
$MyKeys = $MyKeyData.Values

# Apply specified filters
if ($NoServer) {
    foreach ($Item in $MyKeys) {
        $Item.Name = $Item.Name -replace "-[0-9A-Z' ]+$",''
    }
}
if ($Anonymous) {
    $MyKeys = $MyKeys | Select-Object -Property * -ExcludeProperty Name
    $OutputProperties.Property.Remove("Name")
}


# Output data
$MyKeys |
    Select-Object -ExcludeProperty TimeStamp |
    Select-Object @OutputProperties |
    Sort-Object -Property Faction,@{E='Dungeon';D=$false},@{E='Level';D=$true},Name,Class


# Write changes to configuration file
if ($ConfigChanged) {
    Write-Verbose "Writing changes to configuration file '$ConfigFilePath' ..."
    if ($PSCmdlet.ShouldProcess) {
        $Config | ConvertTo-Json -Depth 1 | Set-Content -Encoding utf8 -Path $ConfigFilePath
    }
    if ($ConfigHash -eq (Get-FileHash -Algorithm SHA256 -Path $ConfigFilePath).Hash ) {
        Write-Error "There was an error writing configuration to file '$ConfigFilePath'."
    } else {
        Write-Verbose "Changes were successfully written to file '$ConfigFilePath'."
    }
}

#-----------------------------------------------------[End]--------------------------------------------------------
"End" | Write-Debug

