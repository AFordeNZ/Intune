$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "8.8.1"
$validationFile = "$validation\Notepad++.txt"
$content = Get-Content -Path $validationFile

if ($content -eq $version) {
	Write-Host "Found it!"
}
