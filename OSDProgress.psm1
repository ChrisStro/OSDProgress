# Set variables in module scope
###################################################
$Script:UIPath = Join-Path $PSScriptRoot "UI"
$Script:DefaultTemplate = Join-Path $UIPath "DefaultTemplate.psd1"
New-Variable -Name ProgressUI -Scope Script

# Implement your module commands in this script.
###################################################
Get-ChildItem $PSScriptRoot\Public -Include *.ps1 -Recurse | ForEach-Object {
  . $_.FullName;
  Export-ModuleMember -Function $_.BaseName
}

Get-ChildItem $PSScriptRoot\Private -Include *.ps1 -Recurse | ForEach-Object {
  . $_.FullName
}