#Requires -Version 3

<#
.SYNOPSIS
    Read the AstralKeys SavedVariables from your WoW folder and output to screen or to a file.
.DESCRIPTION
    The `WoWAstralKeys` script will check your World of Warcraft install folder and read the AstralKeys SavedVariables files for all accounts and then output them to the screen.

    You can also use options to output the data to a CSV or a JSON file, or sanitize specific features such as removing server name, or hiding the names of the characters.

    Use this script to dump all your keys so you can easily share with your friends!
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Version:            v1.0.0
    Author(s):          RavenDT (https://github.com/RavenDT)
    Maintainer(s):      RavenDT (https://github.com/RavenDT)
    Website:            https://github.com/RavenDT/WoWAstralKeys
    Modified Date:      2022-02-15
    Purpose/Change:     - Initial Release
    License:            MIT License
.EXAMPLE
    PS> .\WoWAstralKeys.ps1

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
    PS> .\WoWAstralKeys.ps1 -Faction Horde

    Name                   Faction  Class        Dungeon            Level WeeklyBest
    ----                   -------  -----        -------            ----- ----------
    Character6-Server3     Horde    Mage         Theater of Pain       10          0
    Character7-Server3     Horde    Paladin      No key                 0          0
.EXAMPLE
    PS> .\WoWAstralKeys.ps1 -FilterNoKeys

    Name                   Faction  Class        Dungeon            Level WeeklyBest
    ----                   -------  -----        -------            ----- ----------
    Character1-Server1     Alliance Demon Hunter De Other Side         17         15
    Character2-Server1     Alliance Paladin      Halls of Atonement    16         15
    Character4-Server2     Alliance Monk         Plaguefall            10          7
    Character5-Server2     Alliance Hunter       Theater of Pain       15          0
    Character6-Server3     Horde    Mage         Theater of Pain       10          0
.EXAMPLE
    PS> .\WoWAstralKeys.ps1 -NoServer

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
    PS> .\WoWAstralKeys.ps1 -Anonymous

    Name Faction  Class        Dungeon            Level WeeklyBest
    ---- -------  -----        -------            ----- ----------
         Alliance Demon Hunter De Other Side         17         15
         Alliance Paladin      Halls of Atonement    16         15
         Alliance Warrior      No key                 0          0
         Alliance Monk         Plaguefall            10          7
         Alliance Hunter       Theater of Pain       15          0
         Horde    Mage         Theater of Pain       10          0
         Horde    Paladin      No key                 0          0
.EXAMPLE
    PS> .\WoWAstralKeys.ps1 -OutputFormat CSV -Path '.\WoWKeys.csv'

    PS> Get-Content -Path '.\WoWKeys.csv'
    "Name","Faction","Class","Dungeon","Level","WeeklyBest"
    "Character1-Server1","Alliance","Demon Hunter","De Other Side","17","15"
    "Character2-Server1","Alliance","Paladin","Halls of Atonement","16","15"
    "Character3-Server1","Alliance","Warrior","No key","0","0"
    "Character4-Server2","Alliance","Monk","Plaguefall","10","7"
    "Character5-Server2","Alliance","Hunter","Theater of Pain","15","0"
    "Character6-Server3","Horde","Mage","Theater of Pain","10","0"
    "Character7-Server3","Horde","Paladin","No key","0","0"
#>

#----------------------------------------------[Script Parameters]-------------------------------------------------

[CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
Param (
    # Choose a specific faction to output. (Default: Both factions)
    [Parameter()]
    [ValidateSet('Alliance','Horde')]
    [String]$Faction,

    # Do not return characters that do not have keys.
    [Parameter()]
    [Switch]$FilterNoKeys,

    # Remove server names from character names.
    [Parameter(ParameterSetName = 'NoServer', Mandatory = $true)]
    [Parameter(ParameterSetName = 'NoServerOutFile', Mandatory = $true)]
    [Switch]$NoServer,

    # Remove character names from output.
    [Parameter(ParameterSetName = 'Anonymous', Mandatory = $true)]
    [Parameter(ParameterSetName = 'AnonymousOutFile', Mandatory = $true)]
    [Switch]$Anonymous,

    # Specify the format for file write.
    [Parameter(ParameterSetName = 'OutFile', Mandatory = $true)]
    [Parameter(ParameterSetName = 'NoServerOutFile', Mandatory = $true)]
    [Parameter(ParameterSetName = 'AnonymousOutFile', Mandatory = $true)]
    [ValidateSet('CSV','JSON')]
    [String]$OutputFormat,

    # Specify the file name of the file to write.
    [Parameter(ParameterSetName = 'OutFile', Mandatory = $true)]
    [Parameter(ParameterSetName = 'NoServerOutFile', Mandatory = $true)]
    [Parameter(ParameterSetName = 'AnonymousOutFile', Mandatory = $true)]
    [Alias('File','FilePath')]
    [String]$Path
)

#-----------------------------------------------[Initializations]--------------------------------------------------

$EASC = @{ ErrorAction = 'SilentlyContinue' }

# Find the 'lua' command on the system
$Lua = Get-Command 'lua' @EASC
$Lua = if ($Lua) { $Lua.Path } else {
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
if (!$Lua) {
    throw "'Lua' command was not found; exiting."
    exit
}

# Load stored configuration file
$ConfigFilePath = Join-Path -Path '~' -ChildPath '.wakconfig'
if ( -not (Resolve-Path @EASC -Path $ConfigFilePath) ) {
    Write-Verbose 'Configuration file was not found.'
    $Config = [PSCustomObject]@{
        WoWPath = ''
    }
    $ConfigHash = $null
} else {
    $Config = Get-Content -Path $ConfigFilePath | ConvertFrom-Json
    $ConfigHash = (Get-FileHash -Algorithm SHA256 -Path $ConfigFilePath).Hash
}
<#
    Stored config should have:
    - WoWPath - The location of the WoW install (default: 'C:\World of Warcraft')
#>
$ConfigChanged = $false

# Make sure we know where WoW is installed
if ( -not $Config.WoWPath -or -not (Test-Path $Config.WoWPath) ) {
    # Check default install location(s) before asking the user
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

#------------------------------------------------[Declarations]----------------------------------------------------

$FACTION_ = @{
    '0' = 'Alliance'
    '1' = 'Horde'
}

$CLASS = @{
    DEATHKNIGHT = 'Death Knight'
    DEMONHUNTER = 'Demon Hunter'
    DRUID       = 'Druid'
    HUNTER      = 'Hunter'
    MAGE        = 'Mage'
    MONK        = 'Monk'
    PALADIN     = 'Paladin'
    PRIEST      = 'Priest'
    ROGUE       = 'Rogue'
    SHAMAN      = 'Shaman'
    WARLOCK     = 'Warlock'
    WARRIOR     = 'Warrior'
}

$DUNGEON = @{
    '375' = 'Mists of Tirna Scithe'
    '376' = 'The Necrotic Wake'
    '377' = 'De Other Side'
    '378' = 'Halls of Atonement'
    '379' = 'Plaguefall'
    '380' = 'Sanguine Depths'
    '381' = 'Spires of Ascension'
    '382' = 'Theater of Pain'
}

#--------------------------------------------------[Functions]-----------------------------------------------------

function Invoke-WAKCharacterExtraction {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$InputObject
    )

    Process {
        $Object = if ($InputObject.AstralCharacters) { $InputObject.AstralCharacters } else { $_ }
        
        foreach ($Item in $Object) {
            if (!$MyKeyData[$Item.unit]) { $MyKeyData[$Item.unit] = @{} }
            $MyKeyData[$Item.unit].Name = $Item.unit
            $MyKeyData[$Item.unit].Class = $CLASS[$Item.class]
            $MyKeyData[$Item.unit].Faction = $FACTION_."$($Item.faction)"
            $MyKeyData[$Item.unit].Dungeon = 'No key'
            $MyKeyData[$Item.unit].Level = 0
            $MyKeyData[$Item.unit].WeeklyBest = $Item.weekly_best
        }
    }
}

function Invoke-WAKKeystoneExtraction {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$InputObject
    )

    Process {
        $Object = if ($_.AstralKeys) { $_.AstralKeys } else { $_ }
        $ObjectFiltered = $Object | Where-Object -Property 'unit' -In $MyKeyData.Keys
        foreach ($Item in $ObjectFiltered) {
            if (!$MyKeyData[$Item.unit]) {
                $MyKeyData[$Item.unit] = @{
                    Name = $Item.unit
                    Class = 'Unknown'
                    Faction = 'Unknown'
                    Dungeon = $DUNGEON."$($Item.dungeon_id)"
                    Level = $Item.key_level
                    WeeklyBest = $Item.weekly_best
                    TimeStamp = $Item.time_stamp
                }
            } elseif ($MyKeyData[$Item.unit].TimeStamp -lt $Item.time_stamp) {
                $MyKeyData[$Item.unit].Dungeon = $DUNGEON."$($Item.dungeon_id)"
                $MyKeyData[$Item.unit].Level = $Item.key_level
                $MyKeyData[$Item.unit].TimeStamp = $Item.time_stamp
            }
        }
    }
}

#--------------------------------------------------[Execution]-----------------------------------------------------

$AKTargetPath = @(
    $Config.WoWPath,
    '_retail_',
    'WTF',
    'Account',
    '*',
    'SavedVariables',
    'AstralKeys.lua'
) -join [IO.Path]::DirectorySeparatorChar
$AKTargetFiles = Get-ChildItem -Path $AKTargetPath -Recurse

foreach ($File in $AKTargetFiles) {
    $ImportJson = ( & $Lua ".\AK_Lua_to_Json.lua" "$File" )
    $ImportObject = $ImportJson | ConvertFrom-Json
    $ImportObject | Invoke-WAKCharacterExtraction
    $ImportObject | Invoke-WAKKeystoneExtraction
}

# Convert Hashtable to PSCustomObject
$MyKeys = $MyKeyData.Values |
    ConvertTo-Json |
    ConvertFrom-Json

# Apply specified filters
if ($Faction) {
    $MyKeys = $MyKeys | Where-Object -Property Faction -Eq $Faction
}
if ($FilterNoKeys) {
    $MyKeys = $MyKeys | Where-Object -Property Dungeon -Ne 'No key'
}
if ($NoServer) {
    for($i = 0; $i -lt $MyKeys.Count; $i++) {
        $MyKeys[$i].Name = $MyKeys[$i].Name -replace "-[0-9A-Z' ]+$",''
    }
}
if ($Anonymous) {
    $MyKeys = $MyKeys | Select-Object -Property * -ExcludeProperty Name
}


# Output data as a table
$MyKeys |
    Sort-Object -Property Faction,Dungeon,@{E='Level';D=$true},Name,Class | 
    Format-Table Name,Faction,Class,Dungeon,Level,WeeklyBest

if ($OutputFormat) {
    switch ($OutputFormat) {
        CSV  {
            $OutputString = $MyKeys |
                Select-Object -Property Name,Faction,Class,Dungeon,Level,WeeklyBest |
                ConvertTo-Csv -NoTypeInformation
        }
        JSON { $OutputString = $MyKeys | ConvertTo-Json }
    }

    $OutputString | Set-Content -Encoding utf8 $Path
}


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

