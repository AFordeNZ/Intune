$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "3.13.3"
$validationFile = "$validation\Python 3.13.3 (64-bit).txt"
$content = Get-Content -Path $validationFile

if ($content -eq $version) {
	Write-Host "Found it!"
}
