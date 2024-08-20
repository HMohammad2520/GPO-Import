# Get the current script's directory
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define the path to the backup folder relative to the script's directory
$BackupFolder = Join-Path -Path $ScriptDir -ChildPath "Backup"

# Get a list of backup directories
$BackupDirs = Get-ChildItem -Path $BackupFolder -Directory

# Import GPMC module if not already imported
if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
    Import-Module GroupPolicy
}

foreach ($BackupDir in $BackupDirs) {
    Write-Output "Processing backup directory: $($BackupDir.FullName)"
    
    # Path to the Backup.xml file
    $XMLPath = Join-Path -Path $BackupDir.FullName -ChildPath "Backup.xml"
    
    if (Test-Path -Path $XMLPath) {
        try {
            # Load the XML content
            $XMLContent = [xml](Get-Content -Path $XMLPath -Raw)
            
            # Extract the GPO DisplayName
            $GPOName = $XMLContent.'GroupPolicyBackupScheme'.'GroupPolicyObject'.'GroupPolicyCoreSettings'.'DisplayName'.InnerText
            
            if (-not $GPOName) {
                Write-Warning "Failed to determine GPO name from XML file: $($XMLPath)"
                continue
            }
            
            Write-Output "GPO Name: $GPOName"
            
            # Check if GPO with the name already exists
            $ExistingGPO = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
            
            if (-not $ExistingGPO) {
                # Create a new GPO with the specified name if it does not exist
                New-GPO -Name $GPOName -ErrorAction Stop
            } else {
                Write-Host "GPO with name $GPOName already exists. Overwriting settings."
            }

            # Import settings from the backup into the newly created or existing GPO
            try {
                Write-Host "Importing GPO with BackupId: $($BackupDir.Name) from path: $($BackupFolder)"
                Import-GPO -BackupId $BackupDir.Name -Path $BackupFolder -TargetName $GPOName -CreateIfNeeded -ErrorAction Stop
                Write-Host "Settings imported successfully for GPO: $GPOName"
            } catch {
                Write-Error "Error importing settings for GPO: $GPOName - $_"
            }
            
        } catch {
            Write-Error "Error processing XML file $($XMLPath): $_"
        }
    } else {
        Write-Warning "No Backup.xml file found in backup directory: $($BackupDir.FullName)"
    }
}

Write-Host "All GPOs processed successfully."
