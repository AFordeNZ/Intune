$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "v3.10"
$validationFile = "$validation\Autologon.txt"
$content = Get-Content -Path $validationFile

if ($content -eq $version) {
	Write-Host "Found it!"
}
