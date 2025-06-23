<#
.SYNOPSIS
    Autologon v3.10

.DESCRIPTION
    Script to install Autologon v3.10

.PARAMETER Mode
    Sets the mode of operation. Supported modes are Install or Uninstall

.EXAMPLE 
    powershell.exe -executionpolicy bypass -file .\appinstall.ps1 -Mode Install
    powershell.exe -executionpolicy bypass -file .\appinstall.ps1 -Mode Uninstall

.NOTES
    - AUTHOR: Ashley Forde
    - Version: v3.10
    - Date: 20.05.2025
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
$AppName = "Autologon"
$AppVersion = "v3.10"
$Installer = "Autologon64.exe" # assumes the .exe or .msi installer is in the Files folder of the app package.
$InstallArguments = "UPN DOMAIN PASSWORD /accepteula" #Must Set these before packaging


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
            # Define target setup folder in ProgramData
            $ProgramDataSetupFolder = Join-Path -Path $env:ProgramData -ChildPath $AppName

            # Create the ProgramData setup folder if it doesn't exist
            if (-not (Test-Path $ProgramDataSetupFolder)) {
                New-Item -ItemType Directory -Path $ProgramDataSetupFolder -Force | Out-Null
            }

            # Copy files to ProgramData setup folder
            Copy-Item -Path "$PSScriptRoot\Files\*" -Destination $ProgramDataSetupFolder -Recurse -Force -ErrorAction Stop
            Write-LogEntry -Value "Setup files have been copied to $ProgramDataSetupFolder." -Severity 1

            # Test if there is a setup file
            $SetupFilePath = (Join-Path -Path $ProgramDataSetupFolder -ChildPath $Installer).ToString()

            if (-not (Test-Path $SetupFilePath)) { 
                throw "Error: Setup file not found" 
            }
            Write-LogEntry -Value "Setup file ready at $($SetupFilePath)" -Severity 1

            try {
                # Run setup with custom arguments and create validation file
                Write-LogEntry -Value "Starting $Mode of $AppName" -Severity 1
                $Process = Start-Process $SetupFilePath -ArgumentList $InstallArguments -Wait -PassThru -ErrorAction Stop

                # Post Install Actions
                if ($Process.ExitCode -eq "0") {
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
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
            $regValues = @("DefaultDomainName", "DefaultPassword", "DefaultUserName")

            foreach ($val in $regValues) {
                try {
                    if (Get-ItemProperty -Path $regPath -Name $val -ErrorAction SilentlyContinue) {
                        Remove-ItemProperty -Path $regPath -Name $val -ErrorAction Stop
                        Write-LogEntry -Value "Registry value '$val' removed from $regPath" -Severity 1
                    }
                } catch {
                    Write-LogEntry -Value "Failed to remove registry value '$val': $($_.Exception.Message)" -Severity 2
                }
            }

            # Set AutoAdminLogon to 0
            try {
                Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value 0 -ErrorAction Stop
                Write-LogEntry -Value "Set 'AutoAdminLogon' to 0 in $regPath" -Severity 1
            } catch {
                Write-LogEntry -Value "Failed to set 'AutoAdminLogon' to 0: $($_.Exception.Message)" -Severity 2
            }

            # Delete validation file
            try {
                if (Test-Path $AppValidationFile) {
                    Remove-Item -Path $AppValidationFile -Force -Confirm:$false
                    Write-LogEntry -Value "Validation file has been removed at $AppValidationFile" -Severity 1
                }
            } catch {
                Write-LogEntry -Value "Error deleting validation file. Errormessage: $($_.Exception.Message)" -Severity 3
            }

            # Cleanup app folder
            try {
                if (Test-Path "$ProgramDataSetupFolder") {
                    Remove-Item -Path "$ProgramDataSetupFolder" -Recurse -Force -ErrorAction Continue
                    Write-LogEntry -Value "Cleanup completed successfully" -Severity 1
                }
            } catch {
                Write-LogEntry -Value "Error during folder cleanup: $($_.Exception.Message)" -Severity 2
            }

            Write-LogEntry -Value "Uninstall of $AppName is complete" -Severity 1
        } catch {
            Write-LogEntry -Value "Error completing uninstall. Errormessage: $($_.Exception.Message)" -Severity 3
            throw "Uninstallation halted due to an error"
        }
    }

    default {
        Write-Output "Invalid mode: $Mode"
    }
}
