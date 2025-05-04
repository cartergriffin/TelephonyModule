function Get-AudiocodesIniAsObjects {
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
        $url = "http://$_/api/v1/files/ini"

        $response = Invoke-WebRequest -Method GET -Uri $url -Headers $using:headers
        $content = [System.Text.Encoding]::ASCII.GetString($response.Content)
        $lines = $content.Split("`n")

        foreach ($line in $lines) {
            $stdOut = [PSCustomObject]@{
                DeviceIP = $_
                Line = $line.Trim()
            }
            if ($using:SearchString) {
                if ($line -like "*$($using:SearchString)*") {
                    $stdout
                }
            } else {
                $stdOut
            }
        }
    }

    $results = $ips | Foreach-Object -Parallel $scriptBlock -ThrottleLimit 8
    
    return $results
}