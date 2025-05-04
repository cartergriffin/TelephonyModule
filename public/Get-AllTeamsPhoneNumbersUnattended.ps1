function Get-AllTeamsPhoneNumbersUnattended {
    param()
    $headers = Get-GraphCertToken -asAuthHeader
    $uri = "https://graph.microsoft.com/beta/admin/teams/telephoneNumberManagement/numberAssignments?`$top=1000"
    
    $allNumbers = [System.Collections.Generic.List[object]]::new()
    Get-PaginatedGraphResults -outputListObject $allNumbers -firstUri $uri -headers $headers    
    return $allNumbers
}
