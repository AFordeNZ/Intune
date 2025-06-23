$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "4.4.7"
$validationFile = "$validation\Wireshark.txt"
$content = Get-Content -Path $validationFile

if ($content -eq $version) {
	Write-Host "Found it!"
}
