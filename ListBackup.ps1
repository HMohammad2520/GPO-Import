# Get the current script's directory
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define the path to the backup folder relative to the script's directory
$BackupFolder = Join-Path -Path $ScriptDir -ChildPath "Backup"
Write-Output "Backup Folder: $($BackupFolder.FullName)"

# Get a list of backup directories
$BackupDirs = Get-ChildItem -Path $BackupFolder -Directory

# Import GPMC module if not already imported
if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
    Import-Module GroupPolicy
}

foreach ($BackupDir in $BackupDirs) {
    # Path to the Backup.xml file
    $XMLPath = Join-Path -Path $($BackupDir.FullName) -ChildPath "Backup.xml"

    if (Test-Path -Path $XMLPath) {
        # Load the XML content
        $XMLContent = [xml](Get-Content -Path $XMLPath -Raw)
        
        # Extract the GPO DisplayName
        $GPOName = $XMLContent.'GroupPolicyBackupScheme'.'GroupPolicyObject'.'GroupPolicyCoreSettings'.'DisplayName'.InnerText
    }
    if (-not $GPOName) {
        Write-Warning "Failed to determine GPO name from XML file: $($XMLPath)"
        continue
    }
    
    Write-Output "GUID: $($BackupDir.Name) -- Name: $($GPOName)"
}

Write-Host "Done."
