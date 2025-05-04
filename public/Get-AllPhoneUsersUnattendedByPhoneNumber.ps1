function Get-AllPhoneUsersUnattendedByPhoneNumber {
    $headers = Get-GraphCertToken -asAuthHeader
    $uri = "https://graph.microsoft.com/beta/admin/teams/userConfigurations?`$filter=isEnterpriseVoiceEnabled eq true"
    
    $allPhoneUsers = [System.Collections.Generic.List[object]]::new()
    Get-PaginatedGraphResults -outputListObject $allPhoneUsers -firstUri $uri -headers $headers
    
    $usersWithPhone = [System.Collections.Generic.List[object]]::new()
    $date = Get-Date -Format "MM/dd/yyyy"
    foreach ($user in $allPhoneUsers) {
        # add one entry per number

        if ($user.telephoneNumbers.Count -gt 0) {
            foreach ($number in $user.telephoneNumbers) {
                $usersWithPhone.Add(
                    [PSCustomObject]@{
                        objectId                 = $user.Id
                        isLicensed               = $true
                        isEvEnabled              = $user.isEnterpriseVoiceEnabled
                        userPrincipalName        = $user.userPrincipalName
                        whenChangedAAD           = $user.modifiedDateTime
                        accountType              = $user.accountType
                        telephoneNumber          = $number.telephoneNumber
                        numberAssignmentCategory = $number.assignmentCategory
                        numberAssignmentDate     = $date
                    }
                )
            }
        }
    }
    return $usersWithPhone
}
