$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "24.5.20320.0"
$validationFile = "$validation\Adobe Acrobat (64-bit).txt"
$content = Get-Content -Path $validationFile

if($content -eq $version){
    Write-Host "Found it!"
}