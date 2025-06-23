$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "25060.205.3499.6849"
$validationFile = "$validation\Microsoft Teams.txt"
$content = Get-Content -Path $validationFile

if ($content -eq $version) {
	Write-Host "Found it!"
}
