# Get the current script's directory
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define the path to the backup folder relative to the script's directory and Log file
$BackupFolder = Join-Path -Path $ScriptDir -ChildPath "Backup"
$LogFile = Join-Path -Path $ScriptDir -ChildPath "GPO_Import.log"

# Get a list of backup directories
$BackupDirs = Get-ChildItem -Path $BackupFolder -Directory

# Import GPMC module if not already imported
if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
    Import-Module GroupPolicy
}

# Get the current domain name from environment variables
$DomainName = $env:DOMAINNAME

# Check for Domain name ENV
if (-not $DomainName){
    Write-Host "The ENV for DOMAINNAME is not defined or is empty, please provide the ENV"
    exit
}

# Lopping for each GPO Object
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

            # Retrieve and parse GPO comment (Description property)
            $GPOComment = $ExistingGPO.Description

            if ($GPOComment) {
                try {
                    $CommentContent = $GPOComment | ConvertFrom-Json

                    # Validate 'importable' flag
                    if ($CommentContent.importable -eq $false) {
                        Write-Warning "GPO '$GPOName' is marked as not importable. Skipping..."
                        continue
                    }

                    # Validate domain
                    if ($CommentContent.domain) {
                        if ($CommentContent.domain -ne $DomainName) {
                            Write-Warning "GPO '$GPOName' is intended for domain '$($CommentContent.domain)', current domain is '$DomainName'. Skipping..."
                            continue
                        } else {
                            Write-Output "This Gpo is Specified to this domain '$GPOName'. Applying the GPO..."
                        }
                    } else {
                        Write-Output "This GPO is Global '$GPOName'. Applying the GPO..."
                    }

                    # Information About GPO
                    Write-Output "Description: $($CommentContent.description)"
                    Write-Output "Actions: $($CommentContent.actions -join ', ')"
                    
                    # Check if GPO with the name already exists
                    $ExistingGPO = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue

                    if (-not $ExistingGPO) {
                        # Create a new GPO with the specified name if it does not exist
                        Write-Warning "GPO '$GPOName' does not exist in Management console. Creating as new GPO..."
                        New-GPO -Name $GPOName -ErrorAction Stop
                    } else {
                        Write-Host "GPO with name $GPOName already exists. Overwriting settings."
                    }

                    # Import settings from the backup into the newly created or existing GPO
                    try {
                        Write-Host "Importing GPO with BackupId: $($BackupDir.Name) from path: $($BackupFolder)"
                        Import-GPO -BackupId $BackupDir.Name -Path $BackupFolder -TargetName $GPOName -CreateIfNeeded -ErrorAction Stop *>> $LogFile
                        Write-Host "Settings imported successfully for GPO: $GPOName"
                    } catch {
                        Write-Error "Error importing settings for GPO: $GPOName - $_"
                    }

                } catch {
                    Write-Warning "Failed to parse GPO comment for '$GPOName' as JSON. Skipping this GPO..."
                    continue
                }
            } else {
                Write-Warning "No comment found in GPO '$GPOName'. Skipping GPO import..."
                continue
            }

        } catch {
            Write-Error "Error processing XML file $($XMLPath): $_"
        }
    } else {
        Write-Warning "No Backup.xml file found in backup directory: $($BackupDir.FullName)"
    }
}

Write-Host "All GPOs processed successfully."
