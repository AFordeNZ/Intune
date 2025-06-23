# Load required assemblies
try {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
} catch {
    Write-Host "Failed to load required assemblies." -ForegroundColor Red
    exit 1
}

# Prompt for package name
Write-Host "Please enter the name for this package" -ForegroundColor Yellow
$AppName = Read-Host -Prompt "Enter the folder name for the package"
if ([string]::IsNullOrWhiteSpace($AppName)) {
    Write-Host "Package name cannot be empty." -ForegroundColor Red
    exit 1
}

# Select package folder
Write-Host "Please select the folder for the package" -ForegroundColor Yellow
$packageFolderDialog = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
$packageFolderDialog.SelectedPath = "D:\Code\Intune\Apps\Published\"
$null = $packageFolderDialog.ShowDialog()
$PackageFolder = $packageFolderDialog.SelectedPath

$FolderName = Join-Path $PackageFolder $AppName
Write-Host "Folder name: $FolderName" -ForegroundColor Green

# Create package directory if it doesn't exist
if (-not (Test-Path $FolderName)) {
    try {
        New-Item -Path $FolderName -ItemType "directory" -Force | Out-Null
    } catch {
        Write-Host "Failed to create folder $FolderName $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Folder $FolderName already exists. Moving on." -ForegroundColor Green
}

# Copy common functions
try {
    Write-Host "Copying common functions to $FolderName" -ForegroundColor Green
    Copy-Item -Path "D:\Code\Intune\Apps\Deployment\functions.ps1" -Destination $FolderName -Force
} catch {
    Write-Host "Failed to copy common functions: $_" -ForegroundColor Red
}

# Select deployment files folder
Write-Host "Please select the folder of the deployment files" -ForegroundColor Yellow
$deploymentFolderDialog = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
$deploymentFolderDialog.SelectedPath = "D:\Code\Intune\Apps\Build\"
$null = $deploymentFolderDialog.ShowDialog()
$DeploymentFolder = $deploymentFolderDialog.SelectedPath

# Copy deployment files
try {
    Copy-Item -Path (Join-Path $DeploymentFolder '*') -Destination $FolderName -Recurse -Force
    Write-Host "Files copied to $FolderName" -ForegroundColor Green
} catch {
    Write-Host "Failed to copy deployment files: $_" -ForegroundColor Red
}

# Copy install/uninstall scripts
try {
    Copy-Item -Path "D:\Code\Intune\Apps\Deployment\install.bat" -Destination $FolderName -Force
    Copy-Item -Path "D:\Code\Intune\Apps\Deployment\uninstall.bat" -Destination $FolderName -Force
} catch {
    Write-Host "Failed to copy install/uninstall scripts: $_" -ForegroundColor Red
}

# Prompt user to copy installation files
Write-Host "Please copy the installation files into the package folder: $FolderName" -ForegroundColor Yellow
Write-Host "Press any key to continue after copying the files..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Confirm whether to build the Intunewin file
Write-Host "Do you want to build the .intunewin file now? (Y/N)" -ForegroundColor Yellow
$confirmation = Read-Host
if ($confirmation -notmatch '^[Yy]') {
    Write-Host "Exiting without building .intunewin file." -ForegroundColor Yellow
    Write-Host "Package folder created at: $FolderName" -ForegroundColor Green
    exit 0
}

# Create output directory for .intunewin file
$IntuneOutputFolder = "C:\Temp\$AppName"
if (-not (Test-Path $IntuneOutputFolder)) {
    try {
        New-Item -Path $IntuneOutputFolder -ItemType "directory" -Force | Out-Null
        Write-Host "Created output directory: $IntuneOutputFolder" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create output directory $IntuneOutputFolder : $_" -ForegroundColor Red
        exit 1
    }
}

# Run IntuneWinAppUtil.exe
try {
    Write-Host "Starting IntuneWinAppUtil.exe and compiling .intunewin file" -ForegroundColor Cyan
    Write-Host "Output will be saved to: $IntuneOutputFolder" -ForegroundColor Cyan
    & "D:\Tools\Win32PrepTool\IntuneWinAppUtil.exe" -c "$FolderName" -s "install.bat" -o "$IntuneOutputFolder" -q
} catch {
    Write-Host "Failed to run IntuneWinAppUtil.exe: $_" -ForegroundColor Red
}

# Open Explorer at Intune output location
try {
    Write-Host "Opening Explorer at Intune output location" -ForegroundColor Cyan
    Invoke-Item -Path $IntuneOutputFolder
} catch {
    Write-Host "Failed to open Explorer: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 2
Clear-Host