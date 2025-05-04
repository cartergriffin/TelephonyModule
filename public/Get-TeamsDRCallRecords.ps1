function Get-TeamsDRCallRecords {
    param (
        [string]$CallerNumber,
        [string]$CalleeNumber,
        [string]$TelephoneNumber,
        [string]$LastMinutes,
        [string]$LastDays
    )

	# add default datetime of last 1 days if not present
    $date = Get-Date

    if ($LastMinutes) {
        $toDateTime = $date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $fromDateTime = $date.AddMinutes(-$LastMinutes).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    if ($LastDays) {
        $toDateTime = $date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $fromDateTime = $date.AddDays(-$LastDays).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }

    # build uri with the date and time range in ISO 8601 format
    $uri = "https://graph.microsoft.com/v1.0/communications/callRecords/getDirectRoutingCalls(fromDateTime=$fromDateTime,toDateTime=$toDateTime)"
    $headers = Get-GraphCertToken -asAuthHeader

    # store all records in list, API offers no filter but date
    $allCallRecords = [System.Collections.Generic.List[object]]::new()
    Get-PaginatedGraphResults -outputListObject $allCallRecords -firstUri $uri -headers $headers

    $filteredRecords = [System.Collections.Generic.List[object]]::new()

    # filter for specific number if a param is passed
    if ($CallerNumber -or $CalleeNumber -or $TelephoneNumber) {
        foreach ($record in $allCallRecords) {
            if (
                ($CalleeNumber -and $record.calleeNumber -like "*$CalleeNumber") -or
                ($CallerNumber -and $record.callerNumber -like "*$CallerNumber") -or
                ($TelephoneNumber -and (
                    $record.calleeNumber -like "*$TelephoneNumber" -or 
                    $record.callerNumber -like "*$TelephoneNumber"
                ))
            ) {
                $filteredRecords.Add($record)
            }
        }

        $sorted = $filteredRecords | Sort-Object -Property inviteDateTime
        return $sorted
    } else {
        return $allCallRecords
    }
}