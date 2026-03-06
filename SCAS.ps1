[CmdletBinding(DefaultParameterSetName="Help")]
param(
    # LIST
    [Parameter(Mandatory=$true, ParameterSetName="List")]
    [Alias("l")]
    [switch]$list,

    [Parameter(ParameterSetName="List")]
    [Alias("a")]
    [switch]$all,

    # SAVE
    [Parameter(Mandatory=$true, ParameterSetName="Save")]
    [Alias("s")]
    [switch]$save,

    # OVERRIDE (force save even if name exists)
    [Parameter(ParameterSetName="Save")]
    [Alias("o")]
    [switch]$override,

    # HIDE
    [Parameter(Mandatory=$true, ParameterSetName="Hide")]
    [string]$hide,

    # UN-HIDE
    [Parameter(Mandatory=$true, ParameterSetName="Unhide")]
    [string]$unhide,

    # CHANGE
    [Parameter(Mandatory=$true, ParameterSetName="Change")]
    [Alias("c")]
    [string]$change,

    # DELETE
    [Parameter(ParameterSetName="Delete")]
    [AllowNull()]
    [AllowEmptyString()]
    [Alias("d")]
    [switch]$delete,

    # NAME (used by Save and Delete)
    [Parameter(Mandatory=$true, ParameterSetName="Save", Position=0)]
    [Parameter(ParameterSetName="Delete", Position=0)]
    [string]$name,

    # Storage Location
    [Parameter(ParameterSetName="StorageLocation")]
    [Alias("sl")]
    [switch]$sloc,

    # HELP
    [Parameter(ParameterSetName="Help")]
    [Alias("h")]
    [switch]$help
)

# -----------------------------
# Detect Steam Path
# -----------------------------
function Get-SteamPath {
    # Try registry
    try {
        $path = (Get-ItemProperty "HKCU:\Software\Valve\Steam").SteamPath
        if (Test-Path "$path\steam.exe") { return $path }
    } catch {}

    # Try running process
    $process = Get-Process steam -HostAction SilentlyContinue
    if ($process) { return Split-Path $process.Path }

    # Check common paths
    $commonPaths = @(
        "C:\Program Files (x86)\Steam",
        "C:\Program Files\Steam",
        "D:\Steam"
    )

    foreach ($p in $commonPaths) {
        if (Test-Path "$p\steam.exe") { return $p }
    }

    return $null
}

$steamPath = Get-SteamPath

if ($steamPath) {
    Write-Host "Steam detected at: $steamPath"
} else {
    Write-Host "Steam installation not found."
    exit
}

# -----------------------------
# Detect Active User
# -----------------------------
$loginFile = "$steamPath\config\loginusers.vdf"

$content = Get-Content $loginFile -Raw

# Find current active user
if ($content -match '"(\d+)"\s*{[^}]*"MostRecent"\s*"1"') {
    $userBlock = $matches[0]
    $steamId64 = [int64]$matches[1]
    $accountId = $steamId64 - 76561197960265728

    # PersonaName
    if ($userBlock -match '"PersonaName"\s*"([^"]+)"') {
        $personaName = $matches[1]
    }

    Write-Host "SteamID64: $steamId64"
    Write-Host "AccountID: $accountId"
    Write-Host "PersonalName: $personaName"
} else {
    Write-Host "No active Steam user found."
    exit 1
}

Write-Host ""

# -----------------------------
# PATH CONFIGURATION
# -----------------------------

# User-specific paths
$configPath = "$steamPath\userdata\$accountId\config"
$gridPath = "$configPath\grid"

# Default SCAS storage paths
$gridSCASPath = "$steamPath\userdata\SCAS_grid"
$hiddenPath = "$gridSCASPath\.hidden"

# Ensure storage directories exist
New-Item -ItemType Directory -Force -Path $gridSCASPath | Out-Null
New-Item -ItemType Directory -Force -Path $hiddenPath | Out-Null

# -----------------------------
# FUNCTIONS
# -----------------------------
function Save-Grid($Name) {

    if (!(Test-Path $gridPath)) {
        Write-Host "Grid folder not found." -ForegroundColor Red
        exit 1
    }

    $visibleDest = Join-Path $gridSCASPath $Name
    $hiddenDest  = Join-Path $hiddenPath $Name

    $existingPath = $null

    if (Test-Path $visibleDest) { $existingPath = $visibleDest }
    elseif (Test-Path $hiddenDest) { $existingPath = $hiddenDest }

    # Handle existing grid
    if ($existingPath) {

        if (-not $override) {
            Write-Host "Grid '$Name' already exists. Use -o to override." -ForegroundColor Red
            exit 1
        }

        Write-Host "Overriding existing grid '$Name'..." -ForegroundColor Yellow
        Remove-Item $existingPath -Recurse -Force
        $dest = $existingPath
    }
    else {
        $dest = $visibleDest
    }

    Copy-Item $gridPath $dest -Recurse -ErrorAction Stop

    Write-Host "Grid '$Name' saved successfully." -ForegroundColor Green
}

function List-Grids($IncludeHidden) {

    Write-Host "Grids:"

    Get-ChildItem $gridSCASPath -Directory |
        Where-Object { $_.Name -ne ".hidden" } |
        ForEach-Object { Write-Host "  $($_.Name)" }

    if ($IncludeHidden) {
        Get-ChildItem $hiddenPath -Directory |
            ForEach-Object { Write-Host "  [HIDDEN] $($_.Name)" }
    }
}

function Hide-Grid($Name) {

    $src  = "$gridSCASPath\$Name"
    $dest = "$hiddenPath\$Name"

    if (!(Test-Path $src)) {
        Write-Host "Grid not found." -ForegroundColor Red
        exit 1
    }

    Move-Item $src $dest
    Write-Host "Grid '$Name' hidden." -ForegroundColor Yellow
}

function Unhide-Grid($Name) {

    $src  = "$hiddenPath\$Name"
    $dest = "$gridSCASPath\$Name"

    if (!(Test-Path $src)) {
        Write-Host "Hidden grid not found." -ForegroundColor Red
        exit 1
    }

    Move-Item $src $dest
    Write-Host "Grid '$Name' unhidden." -ForegroundColor Yellow
}

function Change-Grid($Name) {

    $newGridPath = "$gridSCASPath\$Name"

    if (!(Test-Path $newGridPath)) {
        $newGridPath = "$hiddenPath\$Name"

        if(!(Test-Path $newGridPath)) {
            Write-Host "Grid not found." -ForegroundColor Red
            exit 1
        }
    }

    # Stop Steam
    Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 2

    # Replace grid
    Remove-Item $gridPath -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item $newGridPath $gridPath -Recurse

    # Clear cache
    Remove-Item "$steamPath\appcache\librarycache" -Recurse -Force -ErrorAction SilentlyContinue

    # Restart Steam
    Start-Process "$steamPath\steam.exe"

    Write-Host "Switched to grid '$Name'." -ForegroundColor Green
}

function Delete-Grid($Name) {

    # -----------------------------
    # CASE 1: ./SCAS.ps1 -delete
    # Backup current grid then delete it
    # -----------------------------
    if (-not $Name) {

        if (!(Test-Path $gridPath)) {
            Write-Host "Grid folder not found." -ForegroundColor Red
            exit 1
        }

        $backupName = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $backupPath = "$gridSCASPath\$backupName"

        Write-Host "Creating backup: $backupName" -ForegroundColor Yellow
        Copy-Item $gridPath $backupPath -Recurse

        # Write-Host "Stopping Steam..."
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep 2

        # Remove-Item $gridPath -Recurse -Force
        Remove-Item "$steamPath\appcache\librarycache" -Recurse -Force -ErrorAction SilentlyContinue

        Start-Process "$steamPath\steam.exe"

        Write-Host "Current grid deleted." -ForegroundColor Green
        return
    }

    # -----------------------------
    # CASE 2: ./SCAS.ps1 -delete gridName
    # -----------------------------
    $gridStoragePath = "$gridSCASPath\$Name"
    $hiddenGridStoragePath = "$hiddenPath\$Name"

    if (Test-Path $gridStoragePath) {
        Remove-Item $gridStoragePath -Recurse -Force
        Write-Host "Grid '$Name' deleted." -ForegroundColor Green
        return
    }

    if (Test-Path $hiddenGridStoragePath) {
        Remove-Item $hiddenGridStoragePath -Recurse -Force
        Write-Host "Hidden grid '$Name' deleted." -ForegroundColor Green
        return
    }

    Write-Host "Grid '$Name' not found." -ForegroundColor Red
    exit 1
}

function Get-GridsSaveLocation {
    $normalizedPath = $gridSCASPath -replace '\\','/'
    $normalizedPath | Set-Clipboard
    Write-Host "Grids location copied to clipboard:" -ForegroundColor Green
    Write-Host "  $normalizedPath" -ForegroundColor Cyan
}

function Show-Help {
    Write-Host ""
    Write-Host "Steam Custom Artwork Switcher (SCAS)"
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  SCAS.ps1 [command] [options]"
    Write-Host ""
    Write-Host "COMMANDS:"
    Write-Host "  -help,   -h                 Show this help"
    Write-Host ""
    Write-Host "  -save,   -s   <name>        Save current grid"
    Write-Host "           -o                 Override if name exists (use with -save)"
    Write-Host ""
    Write-Host "  -list,   -l                 List visible grids"
    Write-Host "           -a                 Include hidden grids (use with -list)"
    Write-Host ""
    Write-Host "  -change, -c   <name>        Switch to a grid"
    Write-Host ""
    Write-Host "  -delete, -d                 Backup and delete current grid"
    Write-Host "  -delete, -d   <name>        Delete a specific grid"
    Write-Host ""
    Write-Host "  -hide         <name>        Hide a grid"
    Write-Host "  -unhide       <name>        Unhide a grid"
    Write-Host ""
    Write-Host "  -sloc,   -sl                Show grids save location"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "  ./SCAS.ps1 -s clean_grid"
    Write-Host "  ./SCAS.ps1 -l"
    Write-Host "  ./SCAS.ps1 -l -a"
    Write-Host "  ./SCAS.ps1 -c clean_grid"
    Write-Host "  ./SCAS.ps1 -d"
    Write-Host "  ./SCAS.ps1 -d clean_grid"
    Write-Host ""
}

# -----------------------------
# PARAMETER ROUTING
# -----------------------------
switch ($PSCmdlet.ParameterSetName) {
    "List"            { List-Grids $all }
    "Save"            { Save-Grid $name }
    "Hide"            { Hide-Grid $hide }
    "Unhide"          { Unhide-Grid $unhide }
    "Change"          { Change-Grid $change }
    "Delete"          { Delete-Grid $name }
    "StorageLocation" { Get-GridsSaveLocation }
    "Help"            { Show-Help }
    default           { Show-Help }
}
