$Folder = "$($env:homedrive)\HUD"
$validation = "$Folder\02_Validation"
$version = "2.142.928.0"
$validationFile = "$validation\Microsoft Power BI Desktop.txt"
$content = Get-Content -Path $validationFile

if($content -eq $version){
    Write-Host "Found it!"
}