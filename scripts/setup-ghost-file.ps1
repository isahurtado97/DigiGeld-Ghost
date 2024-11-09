param(
    $filepath,
    $filefinalpath,
    $password,
    $image,
    $appikey
)
process{
    $file = Get-Content $filepath
    $file = $file -replace 'CHANGE_PASSWORD', $password
    $file = $file -replace 'CHANGE_IMAGE', $image
    $file = $file -replace 'APPINSIGHTS_INSTRUMENTATIONKEY', $appikey
    $file | Out-File -FilePath $filefinalpath
}