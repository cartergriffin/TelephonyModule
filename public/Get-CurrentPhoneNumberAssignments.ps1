# requires yesterday's results
# might need to refactor this to allow for init
function Get-CurrentPhoneNumberAssignments {

    $config = Get-TelephonyModuleConfig
    $outputDirPath = $config.currentPhoneCsvPath
    $checkPath = Test-Path -path $outputDirPath
    if (-not $checkPath) {
        try {
            mkdir $config.currentPhoneCsvPath
        } catch {
            throw "unable to write new dir at $outputDirPath"
            break
        }
    }
    $yesterDayCsvDir = Get-ChildItem -path $outputDirPath
    $csvSorted = $yesterDayCsvDir | sort-object -Property LastWriteTime -Descending
    $csvPath = $csvSorted[0].FullName
    $yesterDayCsv = Import-Csv -path $csvPath

    # init empty dictionary to enable fast lookup of yesterdayCsv by tn
    $tnToYesterday = [System.Collections.Generic.Dictionary[string, object]]::new()
    foreach ($row in $yesterDayCsv) {
        $tnToYesterday["$($row.telephoneNumber)"] = $row
    }

    $firstListOfAllPhoneNumberObjects = Get-AllTeamsPhoneNumbersUnattended
    $allPhoneUsers = Get-AllPhoneUsersUnattendedByPhoneNumber

    $formatNumbers = $null
    $sortedNumbers = $null
    
    $userIdToUpn = [System.Collections.Generic.Dictionary[string, object]]::new()
    foreach ($user in $allPhoneUsers) {
        $userIdToUpn["$($user.objectId)"] = [PSCustomObject]@{
            UPN         = $user.userPrincipalName
            AccountType = $user.AccountType
        }
    }

    $formatNumbers = [System.Collections.Generic.List[object]]::new()

    foreach ($number in $firstListOfAllPhoneNumberObjects) {
        $tn = $number.telephoneNumber
        $yesterdayTn = $tnToYesterday["$tn"]
        $targetId = $number.assignmentTargetId
        $user = $userIdToUpn["$targetId"]
        if ($number.assignmentStatus -eq 'Unassigned') {
            $isAvailable = $true
        } else {
            $isAvailable = $false
        }

        $formatNumbers.Add(
            [PSCustomObject]@{
                telephoneNumber           = $tn
                isAvailable               = $isAvailable
                assignmentModifiedDate    = $yesterdayTn.assignmentModifiedDate
                daysUnassigned            = $null
                sourceSystem              = 'Teams'
                teamsNumberType           = $number.numberType
                assignmentStatus          = $number.assignmentStatus
                assignedUserObjectId      = $targetId
                assignedUserPrincipalName = $user.UPN
                assignedUserAccountType   = $user.AccountType
                assignmentCategory        = $number.assignmentCategory
                analogDeviceIP            = $null
                analogFullLine            = $null
                city                      = $number.city
            }
        )
    }

    $existingTns = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($entry in $formatNumbers) {
        $null = $existingTns.Add($entry.telephoneNumber)
    }
    #$dupes = [System.Collections.Generic.List[object]]::new()
    $analogNumbers = Get-AudiocodesATATrunkGroupAssignments
    foreach ($analog in $analogNumbers) {
        $tn = $analog.telephoneNumber
        $yesterdayTn = $tnToYesterday["$tn"]
        # temp measure to avoid duplication before remediating ~40 dupes
        if (-not $existingTns.Contains($tn)) {
            $formatNumbers.Add(
                [PSCustomObject]@{
                    telephoneNumber            = $tn
                    isAvailable                = $false
                    assignmentModifiedDate     = $yesterdayTn.assignmentModifiedDate
                    daysUnassigned             = $null
                    sourceSystem               = 'Analog'
                    teamsNumberType            = $null
                    assignmentStatus           = "Assigned"
                    assignedUserObjectId       = $null
                    assignedUserPrincipalName  = $null
                    assignedUserAccountType    = $null
                    assignmentCategory         = $null
                    analogDeviceIP             = $analog.DeviceIP
                    analogFullLine             = $analog.FullLine
                    city                       = $null
                }
            )
        }<#  
        commenting out for future, NEED TO REMEDIATE DUPE ASSIGNMENTS BEFORE PUSHING THIS TO PROD. 
        else {
            write-host "duplicate across teams analog $tn"
            $dupes.Add($analog)
        } #>
    }

    $fileDate = Get-Date -Format "MMddyyyy_hhmmss"
    $date = Get-Date

    $sortedNumbers = $formatNumbers | Sort-Object -Property telephoneNumber
    $changes = [System.Collections.Generic.List[object]]::new()
    foreach ($todayNum in $sortedNumbers) {
        $todayTn = $todayNum.telephoneNumber
        $yesterdayTn = $tnToYesterday["$todayTn"]

        # if unassigned since yesterday, set assignmentModifiedDate
        
        if (-not $yesterdayTn -or -not $yesterdayTn.assignmentModifiedDate) {
            # brand new number or first time seeing it
            $todayNum.assignmentModifiedDate = $date
            $changes.Add($todayNum)
        }
        elseif ([bool]$todayNum.isAvailable -ne [bool]::Parse($yesterdayTn.isAvailable)) {
            # state changed: update timestamp
            $todayNum.assignmentModifiedDate = $date
            $changes.Add($todayNum)
        }
        # no change, preserve previous assignmentModifiedDate
        else {$todayNum.assignmentModifiedDate = $yesterdayTn.assignmentModifiedDate}
        
        if($todayNum.isAvailable){
            $todayNum.daysUnassigned = [math]::Floor(($date - [datetime]$todayNum.assignmentModifiedDate).TotalDays)
        }
    }
    $changes | Export-Csv -Append -Path "$outputDirPath\Phone_Assignment_Changelog.csv"
    $sortedNumbers | export-csv -Path "$outputDirPath\CurrentPhoneNumberAssignments_$filedate.csv" -NoTypeInformation
    return  $sortedNumbers
}