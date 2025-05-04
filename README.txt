USE OF THIS MODULE INTENTIONALLY REQUIRES CONFIGURATION PER USER PER DEVICE.
FUNCTIONS IN THIS MODULE ARE DESIGNED FOR UNATTENDED USE ONLY, NOT INTERACTIVE.
PASSWORDS, PRIVATE KEYS ARE DESIGNED TO BE SECURELY USED BY THIS SCRIPT. IT DOES
NOT STORE PASSWORDS OR PRIVATE KEYS. PBX PASSWORD MUST BE UPLOADED TO LOCAL SECRETVAULT
AND M365 APP REGISTRATION CERTIFICATE MUST BE GENERATED WITH OPENSSL THEN IMPORTED TO
CERTSTORE ONCE. .PFX FILE SHOULD BE DELETED AFTER IMPORT TO REMOVE PASSWORDLESS PRIVATE
KEY FROM DISK IMMEDIATELY AFTER.

TO USE AUDIOCODES CMDLETS, MUST CONFIGURE SECRETSTORE VIA SECRETMANAGEMENT MODULES
WITH NEW SECRET NAMED "AudioCodes" WITHIN DEFAULT SECRETVAULT. MORE INSTRUCTIONS:

TO USE: SETUP SECRET VAULT + STORE THEN ADD PW AS SECRET IN PLAINTXT
ENSURE SETUP IS DONE WITH ACCOUNT WHICH WILL RUN SCRIPT
https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/get-started/using-secretstore?view=ps-modules
https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/how-to/using-secrets-in-automation?view=ps-modules
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/set-secret?view=ps-modules
# pwsh
Install-Module -Name Microsoft.PowerShell.SecretStore -Repository PSGallery -Force
Install-Module -Name Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force
Import-Module Microsoft.PowerShell.SecretStore
Import-Module Microsoft.PowerShell.SecretManagement

$credential = Get-Credential -UserName 'SecureStore'

PowerShell credential request
Enter your credentials.
Password for user SecureStore: **************

# NOTE THIS PATH DOWN FOR LATER USE IN INSTALL-TELEPHONYMODULECONFIG
$securePasswordPath = 'C:\automation\passwd.xml'
$credential.Password |  Export-Clixml -Path $securePasswordPath
Register-SecretVault -Name SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
$password = Import-CliXml -Path $securePasswordPath

$storeConfiguration = @{
    Authentication = 'Password'
    PasswordTimeout = 3600 # 1 hour
    Interaction = 'None'
    Password = $password
    Confirm = $false
}
Set-SecretStoreConfiguration @storeConfiguration

TO USE GRAPH API TEAMS CMDLETS, MUST CREATE CERT THEN UPLOAD TO APP REGISTRATION
IN ENTRA ID:

GENERATE OPENSSL CERT AS PFX THEN IMPORT W/ PWSH
#  bash 
  openssl genrsa -out <your_certName>.key 2048

  openssl req -new -x509 \
  -key <your_certName>.key \
  -out <your_certName>.crt \
  -days 1095 \
  -subj "/CN=<your_certName>"

  openssl pkcs12 -export \
  -out <your_certName>.pfx \
  -inkey <your_certName>.key \
  -in <your_certName>.crt \
  -certfile <your_certName>.crt \
  -passout pass:

#  pwsh
 Import-PfxCertificate -FilePath "C:\path\to\<your_certName>.pfx" -CertStoreLocation Cert:\CurrentUser\My\
 
 THEN UPLOAD <your_certName>.crt TO CERTIFICATE AREA OF APP REGISTRATION

 AFTER THESE STEPS ARE COMPLETE, RUN Install-TelephonyModuleConfig FROM CLI.
 THIS INSTALL FUNCTION WILL CREATE CONFIG IN C:\Users\<your_user_profile>\Documents\TelephonyModuleConfig
 IT IS RECOMMENDED TO ALSO PLACE YOUR SECRET STORE PASSWORD CLIXML IN THIS DIR
