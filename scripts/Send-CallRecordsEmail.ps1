function Send-CallRecordsEmail {
    param (
        [array]$CallRecords,
        [string]$ToAddress,
        [string]$FromAddress,
        [string]$SMTPServer
    )
        
    $htmlTable = "<table border='1'><tr><th>Caller</th><th>Callee</th><th>Time</th><th>Duration (Seconds)</th></tr>"
    
    foreach ($record in $callRecords) {
        # skip long calls, assume they got thru or left vm
        if ($record.Duration -ge 40) {
            continue
        }
        $time = ([DateTime]::Parse($record.startDateTime))
        $time = $time.AddHours(-7).ToString("MM/dd HH:mm")
        $htmlTable += "<tr><td>$($record.callerNumber)</td><td>$($record.calleeNumber)</td><td>$time</td><td>$($record.duration)</td></tr>"
    }
    
    $htmlTable += "</table>"
    
    $mailParams = @{
        To = $ToAddress
        From = $FromAddress
        Subject = "Missed Calls Report"
        Body = $htmlTable
        BodyAsHtml = $true
        SmtpServer = $SMTPServer
    }
        
    Send-MailMessage @mailParams
}

# Usage with your new function
$missedCalls = Get-TeamsDRCallRecords -CalleeNumber 9285238366 -LastMinutes 10
Send-CallRecordsEmail -CallRecords $missedCalls -ToAddress "de88d363.nau0.onmicrosoft.com@amer.teams.ms" -FromAddress "carter.griffin@nau.edu" -SMTPServer "mailgate.nau.edu"