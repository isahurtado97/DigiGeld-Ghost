param(
    $filepath,
    $filefinalpath,
    $password,
    $image
)
process{
    $file = Get-Content $filepath
    $file = $file -replace 'CHANGE_PASSWORD', $password
    $file = $file -replace 'CHANGE_IMAGE', $image
    $file | Out-File -FilePath $filefinalpath
}