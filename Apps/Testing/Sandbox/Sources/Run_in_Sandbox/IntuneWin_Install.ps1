param (
	[String]$Intunewin_Content_File = "C:\Run_in_Sandbox\Intunewin_Folder.txt",
	[String]$Intunewin_Command_File = "C:\Run_in_Sandbox\Intunewin_Install_Command.txt"
)
if (-not (Test-Path $Intunewin_Content_File) ) {
	EXIT
}
if (-not (Test-Path $Intunewin_Command_File) ) {
	EXIT
}

$Sandbox_Folder = "C:\Run_in_Sandbox"
$ScriptPath = Get-Content -Raw $Intunewin_Content_File
$Command = Get-Content -Raw $Intunewin_Command_File
$Command = $Command.replace('"','')

$FileName = (Get-Item $ScriptPath).BaseName

$Intunewin_Extracted_Folder = "C:\Windows\Temp\intunewin"
New-Item -Path $Intunewin_Extracted_Folder -Type Directory -Force | Out-Null
Copy-Item -Path $ScriptPath -Destination $Intunewin_Extracted_Folder -Force
$New_Intunewin_Path = "$Intunewin_Extracted_Folder\$FileName.intunewin"

Set-Location -Path $Sandbox_Folder
& .\IntuneWinAppUtilDecoder.exe $New_Intunewin_Path -s
$IntuneWinDecoded_File_Name = "$Intunewin_Extracted_Folder\$FileName.decoded.zip"

New-Item -Path "$Intunewin_Extracted_Folder\$FileName" -Type Directory -Force | Out-Null

$IntuneWin_Rename = "$FileName.zip"

Rename-Item -Path $IntuneWinDecoded_File_Name -NewName $IntuneWin_Rename -Force

$Extract_Path = "$Intunewin_Extracted_Folder\$FileName"
Expand-Archive -LiteralPath "$Intunewin_Extracted_Folder\$IntuneWin_Rename" -DestinationPath $Extract_Path -Force

Remove-Item -Path "$Intunewin_Extracted_Folder\$IntuneWin_Rename" -Force
Start-Sleep -Seconds 1

$ServiceUI = "$Sandbox_Folder\ServiceUI.exe"
$PsExec = "$Sandbox_Folder\PsExec.exe"

# Run the PS7 installation prompt
& $PsExec \\localhost -w "C:\PS7" -nobanner -accepteula -s $ServiceUI -Process:explorer.exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command ".\install.bat"

Start-Sleep -Seconds 3

# Run the main command in PowerShell
& $PsExec \\localhost -w "$Extract_Path" -nobanner -accepteula -s $ServiceUI -Process:explorer.exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoExit -NoProfile -ExecutionPolicy Bypass -Command $Command

