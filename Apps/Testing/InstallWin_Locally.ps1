function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Color = "Cyan"
    )
    Write-Host $Prompt -ForegroundColor $Color
    return Read-Host
}

function Test-InputValidation {
    param(
        [string]$ScriptPath,
        [string]$Command
    )
    
    # Guard clause: Check if IntuneWin file exists
    $ScriptPath = $ScriptPath.Trim('"', "'")
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "The specified file does not exist. Exiting..." -ForegroundColor Red
        exit 1
    }
    
    # Guard clause: Check if command is provided
    if ([string]::IsNullOrWhiteSpace($Command)) {
        Write-Host "No command specified. Exiting..." -ForegroundColor Red
        exit 1
    }
    
    return $ScriptPath, $Command.Replace('"', '')
}

function Initialize-WorkingDirectories {
    param(
        [string]$StagingFolder
    )
    
    # Guard clause: Check if staging folder can be created
    try {
        New-Item -Path $StagingFolder -ItemType Directory -Force | Out-Null
    }
    catch {
        Write-Host "Failed to create staging directory: $StagingFolder. Error: $_" -ForegroundColor Red
        exit 1
    }
}

function Invoke-IntuneWinExtraction {
    param(
        [string]$SourcePath,
        [string]$StagingFolder,
        [string]$SandboxFolder,
        [string]$FileName
    )
    
    $NewIntuneWinPath = Join-Path $StagingFolder "$FileName.intunewin"
    $DecodedFilePath = Join-Path $StagingFolder "$FileName.decoded.zip"
    $RenamedZipPath = Join-Path $StagingFolder "$FileName.zip"
    $ExtractPath = Join-Path $StagingFolder $FileName
    
    try {
        # Copy IntuneWin file to staging area
        Copy-Item -Path $SourcePath -Destination $NewIntuneWinPath -Force
        
        # Decode the IntuneWin file
        Push-Location $SandboxFolder
        & .\IntuneWinAppUtilDecoder.exe $NewIntuneWinPath -s
        Pop-Location
        
        # Guard clause: Check if decoded file was created
        if (-not (Test-Path $DecodedFilePath)) {
            throw "Failed to decode IntuneWin file. Decoded file not found: $DecodedFilePath"
        }
        
        # Create extraction directory and process the archive
        New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null
        Rename-Item -Path $DecodedFilePath -NewName "$FileName.zip" -Force
        Expand-Archive -LiteralPath $RenamedZipPath -DestinationPath $ExtractPath -Force
        Remove-Item -Path $RenamedZipPath -Force
        
        return $ExtractPath
    }
    catch {
        Write-Host "Failed to extract IntuneWin file: $_" -ForegroundColor Red
        exit 1
    }
}

function Invoke-SystemCommand {
    param(
        [string]$ExtractPath,
        [string]$Command,
        [string]$PsExecPath
    )
    
    # Guard clause: Check if PsExec exists
    if (-not (Test-Path $PsExecPath)) {
        Write-Host "PsExec not found at: $PsExecPath" -ForegroundColor Red
        exit 1
    }
    
    try {
        Write-Host "Executing command as SYSTEM user..." -ForegroundColor Green
        & $PsExecPath \\localhost -w $ExtractPath -nobanner -accepteula -i -s "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoExit -NoProfile -ExecutionPolicy Bypass -Command $Command
    }
    catch {
        Write-Host "Failed to execute command: $_" -ForegroundColor Red
        exit 1
    }
}

function Invoke-Cleanup {
    param(
        [string]$StagingFolder
    )
    
    $deletePrompt = Read-Host "Do you want to delete the contents of $StagingFolder? (Y/N)"
    if ($deletePrompt -match '^[Yy]') {
        try {
            Remove-Item -Path "$StagingFolder\*" -Recurse -Force
            Write-Host "Deleted contents of $StagingFolder." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to delete $StagingFolder contents: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Staging folder contents were not deleted: $StagingFolder" -ForegroundColor Yellow
    }
}

# Main script execution
try {
    # Configuration
    $SandboxFolder = "D:\Code\Intune\Apps\Testing\Sandbox\Sources\Run_in_Sandbox"
    $StagingFolder = [System.Environment]::ExpandEnvironmentVariables("%SystemRoot%\TEMP")
    $PsExecPath = Join-Path $SandboxFolder "PsExec.exe"
    
    # Get user input
    $ScriptPath = Get-UserInput -Prompt "Please enter the path to the .intunewin file:"
    $Command = Get-UserInput -Prompt "Please enter the installation command to execute:"
    
    # Validate inputs
    $ScriptPath, $Command = Test-InputValidation -ScriptPath $ScriptPath -Command $Command
    $FileName = (Get-Item $ScriptPath).BaseName
    
    # Initialize working environment
    Initialize-WorkingDirectories -StagingFolder $StagingFolder
    
    # Extract IntuneWin file
    $ExtractPath = Invoke-IntuneWinExtraction -SourcePath $ScriptPath -StagingFolder $StagingFolder -SandboxFolder $SandboxFolder -FileName $FileName
    
    # Execute the command
    Invoke-SystemCommand -ExtractPath $ExtractPath -Command $Command -PsExecPath $PsExecPath
    
    # Cleanup
    Invoke-Cleanup -StagingFolder $StagingFolder
}
catch {
    Write-Host "Script execution failed: $_" -ForegroundColor Red
    exit 1
}

