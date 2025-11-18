# dotsource all functions from files, only exporting public
Get-ChildItem "$PSScriptRoot/public/*.ps1" | ForEach-Object {
    . $_.FullName
    Export-ModuleMember -Function $_.BaseName
}
Get-ChildItem "$PSScriptRoot/private/*.ps1" | ForEach-Object {
    . $_.FullName
	Export-ModuleMember -Function $_.BaseName

}