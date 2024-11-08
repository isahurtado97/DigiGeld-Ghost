param(
    $filepath,
    $filefinalpath,
    $password,
    $image ='dgacrprod.azurecr.io/ghost-app:latest'
)
process{
    $file = Get-Content $filepath
    $file = $file -replace 'CHANGE_PASSWORD', $password
    $file = $file -replace 'CHANGE_IMAGE', $image
    $file | Out-File -FilePath $filefinalpath
}