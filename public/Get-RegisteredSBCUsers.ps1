function Get-RegisteredSBCUsers {
    param (
        [string]$basicUserFilter
    )

    $config = Get-TelephonyModuleConfig
    $uri = "http://$($config.sbcIp)/api/v1/actions/authToken"

    $headers = Get-AudioCodesSecret
    
    $body = @{
        username = 'Admin'
        privLevel = 'admin'
        sessionTimeout = 180
    } | convertto-Json

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    $authResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body
    $authToken = $authResponse.authToken

    $goodUri = "http://$($config.sbcIp)/index.html?mode=web&authToken=$authToken"

    # use new $session object to get cookie back 
    $sessionEstablish = Invoke-WebRequest -uri $goodUri -method Get -WebSession $session

    $page = Invoke-WebRequest -Uri "http://$($config.sbcIp)/SASRegUsers" -Method Get -WebSession $session

    $decodedPage = [System.Net.WebUtility]::HtmlDecode($page.Content)
    $split = $decodedPage.Split('<td class="TDbg" WIDTH="30%">')
    # basic user filter to pull users out assuming first 6 phone digits are same
    # and last 4 are unique.
    $regexMatch = "^<sip:(\$basicUserFilter\d{1,4})@(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"
    $parsed = [System.Collections.Generic.List[object]]::new()

    foreach ($line in $split) {
        if ($line -match $regexMatch) {
            $parsed.Add(
                [PSCustomObject]@{
                    DeviceIP = $matches[2]
                    RegisteredNumber = $matches[1]
                }
            )
        }
    }

    $output = $parsed | sort-object -Property RegisteredNumber
    return $output
}
