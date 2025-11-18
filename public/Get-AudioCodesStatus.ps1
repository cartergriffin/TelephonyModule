function Get-AudioCodesStatus {
    [Cmdletbinding()]
    param (
        [string]$SearchString
    )
    $configPath = "$env:userprofile\documents\TelephonyModuleConfig\config.json"
    $config = Get-Content -Path $configPath -ErrorAction SilentlyContinue | ConvertFrom-Json -depth 3
    if (!$config) {
        Write-Host "No config file found at $configPath. Read README.md in $psScriptRoot"
        break
    }

    $ips = $config.pbxIpList

    $headers = Get-AudioCodesSecret
    
    $scriptBlock = {
        $url = "http://$_/api/v1/status"

        $response = Invoke-WebRequest -Method GET -Uri $url -Headers $using:headers
        $content = $response.Content | ConvertFrom-Json
        return $content
    }

    $results = $ips | Foreach-Object -Parallel $scriptBlock -ThrottleLimit 8
    
    return $results
}