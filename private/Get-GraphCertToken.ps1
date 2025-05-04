<#
 purpose is to use locally stored certificate thumbprint against aad app

 TO USE: GENERATE OPENSSL CERT AS PFX THEN IMPORT W/ PWSH
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
 
 THEN UPLOAD CERTIFICATE TO CERTIFICATE AREA OF APP REGISTRATION,
 THEN UPDATE $clientId and $tenantId values in this script
 
  #>
function Get-GraphCertToken {
    param(
        [switch]$asAuthHeader
    )

    $config = Get-TelephonyModuleConfig

    # Load cert from Windows cert store
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -match "CN=$($config.certSubject)" }

    if (-not $cert) {
        throw "Certificate not found. Make sure '$($config.certSubject).pfx' is imported to Cert:\CurrentUser\My"
    }

    # Config
    $thumbprint = $cert.Thumbprint
    $clientId = $config.clientId
    $tenantId = $config.tenantId
    $scope = "https://graph.microsoft.com/.default"

    # base64url encode thumbprint
    $CertificateBase64Hash = [Convert]::ToBase64String($cert.GetCertHash()) -replace '\+','-' -replace '/','_' -replace '='

    # Get private key
    $rsa = $cert.PrivateKey

    # Base64URL function
    function ConvertTo-Base64UrlString {
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $in
        )
        if ($in -is [string]) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($in)
        } elseif ($in -is [byte[]]) {
            $bytes = $in
        } else {
            throw "Invalid input type: $($in.GetType())"
        }
        return [Convert]::ToBase64String($bytes) -replace '\+','-' -replace '/','_' -replace '='
    }

    # JWT header
    $header = @{
        alg = "RS256"
        typ = "JWT"
        x5t = $CertificateBase64Hash
    } | ConvertTo-Json -Compress

    # JWT payload
    $now = Get-Date
    $exp = $now.AddMinutes(10)
    $iat = [int][double]::Parse((Get-Date -Date $now -UFormat %s))
    $expEpoch = [int][double]::Parse((Get-Date -Date $exp -UFormat %s))
    $payload = @{
        aud = "https://login.microsoftonline.com/$tenantId/v2.0"
        iss = $clientId
        sub = $clientId
        iat = $iat
        exp = $expEpoch
        jti = [guid]::NewGuid().ToString()
    } | ConvertTo-Json -Compress

    # encode & sign
    $encodedHeader = ConvertTo-Base64UrlString $header
    $encodedPayload = ConvertTo-Base64UrlString $payload
    $toSign = "$encodedHeader.$encodedPayload"
    $bytesToSign = [System.Text.Encoding]::UTF8.GetBytes($toSign)

    # sign the JWT using RSA + SHA256
    $signatureBytes = $rsa.SignData($bytesToSign, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $encodedSignature = ConvertTo-Base64UrlString $signatureBytes

    # final JWT
    $jwt = "$encodedHeader.$encodedPayload.$encodedSignature"

    # get access token
    $tokenResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id = $clientId
        scope = $scope
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        client_assertion = $jwt
        grant_type = "client_credentials"
    }

    $accessToken = $tokenResponse.access_token
    if ($asAuthHeader -eq $true) {
        return @{ Authorization = "Bearer $accessToken" }
    } else {
        return $accessToken
    }
}