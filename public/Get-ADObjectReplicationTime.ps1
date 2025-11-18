function Get-ADObjectReplicationTime {
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$DistinguishedName
    )
    $dcObjects = Get-ADDomainController -Filter *
    $out = [System.Collections.Generic.List[object]]::new()
    # parallelize later for perf
    foreach ($dc in $dcObjects) {
        $current = $null
        $queryParams = @{
            Properties  = 'whenChanged'
            Server      = $dc.HostName
            ErrorAction = 'SilentlyContinue'
            Filter      = "DistinguishedName -eq '$($DistinguishedName)'"
        }
        $current = Get-ADObject @queryParams
        $out.Add([PScustomObject]@{
            value = $current.Name
            mod = $current.whenChanged
            server = $dc.Name
			site = $dc.site
            })
    }
    $output = $out | Sort-Object -Property mod -Descending
    Write-Output $output
}