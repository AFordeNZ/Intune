$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "135.0.7049.96"
$validationFile = "$validation\Google Chrome.txt"
$content = Get-Content -Path $validationFile

if($content -eq $version){
    Write-Host "Found it!"
}