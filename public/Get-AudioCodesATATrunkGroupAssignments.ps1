function Get-AudiocodesATATrunkGroupAssignments {
    param(
        [string]$phoneRegex
    )
    # using function defined in ~\public\Get-AudioCodesIniAsObjects.ps1. Gets ini from
    # devices and returns one object per ini line containing deviceIP + full line
    $allIniLines = Get-AudioCodesIniAsObjects

    $groupedLinesByDevice = $allIniLines | Group-object -Property DeviceIP

    $iniByDevice = @{}

    foreach ($deviceGroup in $groupedLinesByDevice) {
        $deviceIP = $deviceGroup.Name
        $lines = $deviceGroup.Group | ForEach-Object { $_.Line }  # Strip the DeviceIP now

        $iniByDevice[$deviceIP] = $lines
    }

    # do initial cheap regex match on all lines to find format sections
    function is_section_format {
        param ( [string]$iniLine )
        if ($iniLine -match "^FORMAT") {
            return $true
        } else {
            return $false
        }
    }
    # unused
    function is_section_header {
        param ( [string]$iniLine )
            if ($iniLine -match "^\[(.+?)\]") {
                $currentSectionName = $matches[1]
                continue
            }
    }
    # unused
    function parse_section_format {
        param ( [string]$iniLine )
        if ($iniLine -match "^FORMAT\s+(.+?)\s*=\s*(.+)\;") {
            $indexName = $matches[1]
            $indexAttributes = $matches[2].Split(',').Trim()
        }
    }

    # dotnet list object for performance
    $output = [System.Collections.Generic.List[object]]::new()

    # init hashtable for dictionary
    $sectionSchemasByDevice = @{}

    # forget dictionary for functional reasons just get trunkgroup port assignments
    $trunkGroupOutput = [System.Collections.Generic.List[object]]::new()

    foreach ($deviceIP in $iniByDevice.Keys) {
        $lines = $iniByDevice[$deviceIP]

        # init empty per-device hashtable for all section schemas
        $sectionSchemasByDevice[$deviceIP] = @{}

        foreach ($line in $lines) {
            if ($line -match "^\[\s(.+?)\s\]") {

                # track current section name for OS normalization + parsing logic
                $currentSectionName = $matches[1]
                $output.Add($matches[1])
                continue
            }
            if (is_section_format -iniLine $line) {
                if ($line -match "^FORMAT\s+(.+?)\s*=\s*(.+)\;") {
                    # dynamically return index attrs for each diff section
                    $indexAttributes = $matches[2].Split(',').Trim()
                    
                    # normalize across different audiocodes os versions
                    if ($matches[1] -eq 'Index') {
                        $indexName = "$currentSectionName`_Index"
                    } else {
                        $indexName = $matches[1]
                        # unused
                        $verboseIndexAttrs = $indexAttributes
                    }
                    
                    # add to dictionary
                    $sectionSchemasByDevice[$deviceIP][$indexName] = $indexAttributes
                }
            }
            # forget abt dictionary and use existing logic to get all trunkgroup
            # assignments as nice objects
            if ($currentSectionName = 'TrunkGroup') {
                if ($line -match "^TrunkGroup\s+(\d{1,3})\s+=\s*(.+)\;") {
                    $attrList = $matches[2].Split(',').Trim()
                    $trunkGroupIndex = $matches[1]
                    $phoneNumExtracted = $attrList[4].Trim('"')

                    $stdOut = [PSCustomObject]@{
                        DeviceIP = $deviceIP
                        TrunkGroupIndex = $trunkGroupIndex
                        telephoneNumber = $phoneNumExtracted
                        TrunkGroupId = $attrList[0]
                        BChannelPort = $attrlist[2]
                        FXSModule = $attrList[7]
                        FullLine = $line
                    }

                    # if filter passed, filter
                    if ($phoneRegex) {
                        if ($phoneNumExtracted -match $phoneRegex) {
                            $trunkGroupOutput.Add($stdOut)
                        }
                    # if not, return all trunk group rows as output
                    } else {
                        $trunkGroupOutput.Add($stdOut)
                    }
                }
            }
        }

    }
    return $trunkGroupOutput
}