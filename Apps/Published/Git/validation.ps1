$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "2.49.0"
$validationFile = "$validation\Git.txt"
$content = Get-Content -Path $validationFile

if ($content -eq $version) {
	Write-Host "Found it!"
}
