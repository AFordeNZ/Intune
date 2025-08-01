<#
.SYNOPSIS
    7-Zip File Manager

.DESCRIPTION
    Script to install 7-Zip File Manager

.PARAMETER Mode
    Sets the mode of operation. Supported modes are Install or Uninstall

.EXAMPLE 
    powershell.exe -executionpolicy bypass -file .\appinstall.ps1 -Mode Install
    powershell.exe -executionpolicy bypass -file .\appinstall.ps1 -Mode Uninstall

.NOTES
    - AUTHOR: Ashley Forde
    - Version: 24.09
    - Date: 27.01.2025
#>
# Region Parameters
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Install","Uninstall")]
    [string]$Mode
)

# Reference functions.ps1
. "$PSScriptRoot\functions.ps1"

# Application Variables
$AppName = "Microsoft Teams"
$AppVersion = "25060.205.3499.6849"
$Installer = "teamsbootstrapper.exe" # assumes the .exe or .msi installer is in the Files folder of the app package.
$msixFile = "MSTeams-x64.msix" # Optional, if you want to use the .msix file instead of the .exe installer

# Initialize Directories
$folderpaths = Initialize-Directories -HomeFolder C:\FITC\

# Template Variables
$Date = Get-Date -Format "MM-dd-yyyy"
$stagingFolderVar = $folderPaths.StagingFolder
$logsFolderVar = $folderPaths.LogsFolder
$LogFileName = "$($AppName)_${Mode}_$Date.log"
$validationFolderVar = $folderPaths.ValidationFolder
$AppValidationFile = "$validationFolderVar\$AppName.txt"

# Begin Setup
Write-LogEntry -Value "Initiating setup process" -Severity 1

# Create Setup Folder
$SetupFolder = (New-Item -ItemType "directory" -Path $stagingFolderVar -Name $AppName -Force).FullName
Write-LogEntry -Value "Setup folder has been created at: $Setupfolder." -Severity 1

# Install/Uninstall
switch ($Mode) {
    "Install" {
        try {
            # Copy files to staging folder
            Copy-Item -Path "$PSScriptRoot\Files\*" -Destination $SetupFolder -Recurse -Force -ErrorAction Stop
            Write-LogEntry -Value "Setup files have been copied to $Setupfolder." -Severity 1

            # Test if there is a setup file
            $SetupFilePath = (Join-Path -Path $SetupFolder -ChildPath $Installer).ToString()
            $msixFilePath = (Join-Path -Path $SetupFolder -ChildPath $msixFile).ToString()

            if (-not (Test-Path $SetupFilePath)) { 
                throw "Error: Setup file not found" 
            }
            Write-LogEntry -Value "Setup file ready at $($SetupFilePath)" -Severity 1

            try {
                # Run setup with custom arguments and create validation file
                Write-LogEntry -Value "Starting $Mode of $AppName" -Severity 1
                # Extract the MSIX file from the bootstrapper
                $extractArgs = "-p -o `"$msixFilePath`""
                $Process = Start-Process $SetupFilePath -ArgumentList $extractArgs -Wait -PassThru -ErrorAction Stop
                Write-LogEntry -Value "installing MSIX from bootstrapper with arguments: $extractArgs" -Severity 1
                
                # Check for successful installation
                $installSuccess = $false
                
                # Check if we have a JSON response indicating success
                try {
                    $resultContent = Get-Content -Path "$env:TEMP\TeamsInstallResult.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
                    if ($resultContent -and $resultContent.success -eq $true) {
                        $installSuccess = $true
                        Write-LogEntry -Value "Installation confirmed successful via JSON result" -Severity 1
                    }
                } catch {
                    Write-LogEntry -Value "Could not parse installation result JSON: $($_.Exception.Message)" -Severity 2
                }
                
                # Also check exit code as fallback
                if ($Process.ExitCode -eq 0) {
                    $installSuccess = $true
                }
                
                # Post Install Actions
                if ($installSuccess) {
                    # Create validation file
                    New-Item -ItemType File -Path $AppValidationFile -Force -Value $AppVersion
                    Write-LogEntry -Value "Validation file has been created at $AppValidationFile" -Severity 1
                    Write-LogEntry -Value "Install of $AppName is complete" -Severity 1
                } else {
                    Write-LogEntry -Value "Install of $AppName failed with ExitCode: $($Process.ExitCode)" -Severity 3
                }

                # Cleanup 
                if (Test-Path "$SetupFolder") {
                    Remove-Item -Path "$SetupFolder" -Recurse -Force -ErrorAction Continue
                    Write-LogEntry -Value "Cleanup completed successfully" -Severity 1
                }

            } catch {
                Write-LogEntry -Value "Error running installer. Errormessage: $($_.Exception.Message)" -Severity 3
                return # Stop execution of the script after logging a critical error
            }
        } catch [System.Exception]{ Write-LogEntry -Value "Error preparing installation $FileName $($mode). Errormessage: $($_.Exception.Message)" -Severity 3 }
    }

    "Uninstall" {
        try {
            $AppToUninstall = Get-InstalledApps -App $AppName

            # Uninstall App
            $uninstallProcess = Start-Process $AppToUninstall.UninstallString -ArgumentList $UninstallArguments -PassThru -Wait -ErrorAction stop

            # Post Uninstall Actions
            if ($uninstallProcess.ExitCode -eq "0") {
                # Delete validation file
                try {
                    Remove-Item -Path $AppValidationFile -Force -Confirm:$false
                    Write-LogEntry -Value "Validation file has been removed at $AppValidationFile" -Severity 1

                    # Cleanup 
                    if (Test-Path "$SetupFolder") {
                        Remove-Item -Path "$SetupFolder" -Recurse -Force -ErrorAction Continue
                        Write-LogEntry -Value "Cleanup completed successfully" -Severity 1
                    }
                } catch [System.Exception] {
                    Write-LogEntry -Value "Error deleting validation file. Errormessage: $($_.Exception.Message)" -Severity 3
                }
            } else {
                throw "Uninstallation failed with exit code $($uninstallProcess.ExitCode)"
            }
        } catch [System.Exception] {
            Write-LogEntry -Value "Error completing uninstall. Errormessage: $($_.Exception.Message)" -Severity 3
            throw "Uninstallation halted due to an error"
        }

        Write-LogEntry -Value "Uninstall of $AppName is complete" -Severity 1
    }

    default {
        Write-Output "Invalid mode: $Mode"
    }
}
