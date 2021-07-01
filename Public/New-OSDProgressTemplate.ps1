function New-OSDProgressTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript( {
                if (-Not ($_ | Test-Path -PathType Container) ) {
                    throw "The Path argument must be an existing folder"
                }
                return $true
            })]
        [System.IO.FileInfo]$Path
    )
    Write-Verbose "Create new template file for OSDProgress in $Path"
    $templateFile = Join-Path $Path "OSDProgressTemplate.psd1"
    Copy-Item $Script:DefaultTemplate $templateFile

    # Do some modification to org template
    ###################################################
    $content = Get-Content $templateFile -Raw
    $content -replace "`"Settings`"", "`"Home`"" `
        -replace "`"Phase : Initialize Setup`"", "`"Start from Home`"" `
        -replace "`"CloudDownload`"", "`"Bus`"" `
        -replace "`"Phase : Download Content`"", "`"Driving Bus`"" `
        -replace "`"Monitor`"", "`"City`"" `
        -replace "`"Phase : Post Actions`"", "`"Arrived at work`"" | Set-Content -Path $templateFile

    Get-Item $templateFile
}