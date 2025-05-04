function Get-TelephonyModuleConfig {
    $configPath = "$env:userprofile\documents\TelephonyModuleConfig\config.json"
    $config = Get-Content -Path $configPath -ErrorAction SilentlyContinue | ConvertFrom-Json -depth 3
    if (!$config) {
        Write-Host "No config file found at $configPath. Read README.md in $psScriptRoot"
        break
    }
    return $config
}