param (
    [string]$GhostApiUrl,
    [string]$GhostApiKey
)

$headers = @{
    'Authorization' = "Ghost $GhostApiKey"
    'Content-Type'  = 'application/json'
}

$response = Invoke-RestMethod -Uri "$GhostApiUrl/posts/" -Method Delete -Headers $headers

if ($response.StatusCode -eq 204) {
    Write-Output "All posts deleted successfully."
} else {
    Write-Error "Failed to delete posts: $($response.StatusCode) $($response.Content)"
}
