# hello world

$IniLines = Get-AudiocodesIniAsObjects

$sbcLines = $iniLines | Where-Object {$_.DeviceIP -eq "10.15.75.103"}