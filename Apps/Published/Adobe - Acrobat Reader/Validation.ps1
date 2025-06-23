$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "25.5.20320.0" #correct version is 24.5.20320.0 but this typo is embedded in the .intunewin file
$validationFile = "$validation\Adobe Acrobat Reader.txt"
$content = Get-Content -Path $validationFile

if ($content -eq $version) {
	Write-Host "Found it!"
}