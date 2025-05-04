function Install-TelephonyModuleConfig {
    $path = "$env:userprofile\documents\TelephonyModuleConfig"
    $filename = "config.json"
    $filepath = "$path\$filename"

    $checkAlrExist = Get-Content -path $filepath -erroraction SilentlyContinue | convertfrom-Json

    # break if config file already exists, should be modified
    if ($checkAlrExist) {
        throw "Config already exist at $filepath. Modify existing config or delete to re-run this script"
    }
    # try to create config dir, break if fail
    if (-not (Test-Path -Path $path)) {
        try { mkdir -Path $path } catch { throw "No access to make config dir."}
    }
    if (Test-path -path $path) {
        try {
            $pbxIpList = Read-Host "comma-separated list of audiocodes PBX IP addresses to which you have preexisting REST API access"
            $sbcIp = Read-Host "single IP of main SBC from which to pull registered users list"
            try {
                $pbxIpArray = $pbxIpList.Split(',').Trim()
            } catch {
                throw "bad format for IP list, must be comma separated only"
            }
            $config = @{
                clientId = Read-Host "clientId"
                tenantId = Read-Host "tenantId"
                certSubject = Read-Host "certSubject from Cert:\CurrentUser\My"
                sbcIp = $sbcIp
                pbxIpList = $pbxIpArray
                pbxUsername = Read-Host "audiocodes Pbx username"
                currentPhoneCsvPath = Read-Host "path to persistent CSV and changelog for phone number assignments"
                secretStorePwdPath = Read-Host "preconfigured in README path to secretstore pwd clixml (hopefully within $path)"
            }
            $configJson = $config | convertto-json
            $configJson | out-file -FilePath $filepath
        } catch {
            throw "Unable to write $filePath"
        }
    }
}