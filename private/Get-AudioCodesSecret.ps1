<# 
 GETS PREVIOUSLY-STORED SECRET FROM Microsoft.Security.SecretManagement MODULE
 TO USE: README. SETUP SECRET VAULT + STORE THEN ADD PW AS SECRET IN PLAINTXT
 ENSURE SETUP IS DONE WITH ACCOUNT WHICH WILL RUN SCRIPT
https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/get-started/using-secretstore?view=ps-modules
https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/how-to/using-secrets-in-automation?view=ps-modules
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/set-secret?view=ps-modules
#>

function Get-AudioCodesSecret {

    $config = Get-TelephonyModuleConfig

    $password = Import-CliXml -path $config.secretStorePwdPath
    Unlock-SecretStore -Password $password
    $user = $config.pbxUsername
    $pw = Get-Secret -Name 'AudioCodes' -AsPlainText

    $authString = "$user`:$pw"
    $authHash = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($authString))

    $headers = @{
        Authorization = "Basic $authHash"
    }

    return $headers
}