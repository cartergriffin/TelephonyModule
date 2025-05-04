function Get-PaginatedGraphResults {
    param(
        [string]$firstUri,
        [object]$headers,
        [System.Collections.Generic.List[object]]$outputListObject
    )
    $uri = $firstUri
    do {
        $callResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        $outputListObject.AddRange($callResponse.value)
        $uri = $callResponse.'@odata.nextLink'
    } while ($null -ne $uri)
}
