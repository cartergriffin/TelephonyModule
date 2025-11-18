function Get-CurrentPhoneNumberAssignmentsSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(DontShow)]
        [switch]$dev
    )

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
    
    # if dev, try to get cached m365 info without 60 second call to graph
    if ($dev) {
        try {
            $firstListOfAllPhoneNumberObjects = Get-Content "$env:TEMP\firstPhoneObjList.json" -ErrorAction Stop | ConvertFrom-Json
            $allPhoneUsers = Get-Content "$env:TEMP\firstUserObjList.json" | ConvertFrom-Json
        } catch {
            # running first pass
            $firstListOfAllPhoneNumberObjects = Get-AllTeamsPhoneNumbersUnattended
            $allPhoneUsers = Get-AllPhoneUsersUnattendedByPhoneNumber
            $firstListOfAllPhoneNumberObjects | ConvertTo-Json -depth 5 | out-file "$env:TEMP\firstPhoneObjList.json"
            $allPhoneUsers | ConvertTo-Json -depth 5 | out-file "$env:TEMP\firstUserObjList.json"
        }
        } else {
            $firstListOfAllPhoneNumberObjects = Get-AllTeamsPhoneNumbersUnattended
            $allPhoneUsers = Get-AllPhoneUsersUnattendedByPhoneNumber
        }

<# 
    $firstListOfAllPhoneNumberObjects = Get-AllTeamsPhoneNumbersUnattended
    $allPhoneUsers = Get-AllPhoneUsersUnattendedByPhoneNumber #>

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
        $targetId = $number.assignmentTargetId
        $user = $userIdToUpn["$targetId"]
        if ($number.assignmentStatus -eq 'Unassigned') {
            $isAvailable = $true
        } else {
            $isAvailable = $false
        }

        $formatNumbers.Add(
            [PSCustomObject]@{
                u_telephoneNumber           = $tn
                u_isAvailable               = $isAvailable
                u_sourceSystem              = 'Teams'
                u_teamsNumberType           = $number.numberType
                u_assignmentStatus          = $number.assignmentStatus
                u_assignedUserObjectId      = $targetId
                u_assignedUserPrincipalName = $user.UPN
                u_assignedUserAccountType   = $user.AccountType
                u_assignmentCategory        = $number.assignmentCategory
                u_analogDeviceIP            = $null
                u_analogFullLine            = $null
                u_city                      = $number.city
            }
        )
    }

    $existingTns = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($entry in $formatNumbers) {
        $null = $existingTns.Add($entry.telephoneNumber)
    }
    #$dupes = [System.Collections.Generic.List[object]]::new()
    $analogNumbers = Get-AudiocodesATATrunkGroupAssignments -phoneFilter "+1928523"
    foreach ($analog in $analogNumbers) {
        $tn =  $analog.TelephoneNumber
        # temp measure to avoid duplication before remediating ~40 dupes
        if (-not $existingTns.Contains($tn)) {
            $formatNumbers.Add(
                [PSCustomObject]@{
                    u_telephoneNumber            = $tn
                    u_isAvailable                = $false
                    u_sourceSystem               = 'Analog'
                    u_teamsNumberType            = $null
                    u_assignmentStatus           = "Assigned"
                    u_assignedUserObjectId       = $null
                    u_assignedUserPrincipalName  = $null
                    u_assignedUserAccountType    = $null
                    u_assignmentCategory         = $null
                    u_analogDeviceIP             = $analog.DeviceIP
                    u_analogFullLine             = $analog.FullLine
                    u_city                       = $null
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

    $sortedNumbers = $formatNumbers | Sort-Object -Property telephoneNumber
    $sortedNumbers | export-csv -Path "$outputDirPath\CurrentPhoneNumberAssignments_$filedate.csv" -NoTypeInformation

    return $sortedNumbers
}