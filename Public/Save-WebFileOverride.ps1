<#
.SYNOPSIS
Function to override Save-Webfile function of OSD module with an global alias

.DESCRIPTION
Function for override Save-Webfile function of OSD module with an global alias
#>
function Save-WebFileOverride {
    [CmdletBinding()]
    param (
        #URL of the file to download
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline)]
        [string]$SourceUrl,

        #Destination File Name
        [string]$DestinationName,

        #Destination Folder
        [Alias('Path')]
        [string]$DestinationDirectory = "$env:TEMP\OSD",

        #Overwrite the file if it exists already
        #The default action is to skip the download
        [switch]$Overwrite
    )
    #=======================================================================
    #	DestinationDirectory
    #=======================================================================
    if (Test-Path "$DestinationDirectory") {
    }
    else {
        New-Item -Path "$DestinationDirectory" -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    Write-Verbose "DestinationDirectory: $DestinationDirectory"
    #=======================================================================
    #	DestinationName
    #=======================================================================
    if ($PSBoundParameters['DestinationName']) {
    }
    else {
        $DestinationName = Split-Path -Path $SourceUrl -Leaf
    }
    Write-Verbose "DestinationName: $DestinationName"
    #=======================================================================
    #	WebFileFullName
    #=======================================================================
    $DestinationDirectoryItem = (Get-Item $DestinationDirectory).FullName
    $DestinationFullName = Join-Path $DestinationDirectoryItem $DestinationName

    #=======================================================================
    #	OverWrite
    #=======================================================================
    if ((-NOT ($PSBoundParameters['Overwrite'])) -and (Test-Path $DestinationFullName)) {
        Write-Verbose "DestinationFullName already exists"
        Get-Item $DestinationFullName
    }
    else {

        # Download via Save-OSDProgress function
        $splatt = @{
            URL = $SourceUrl
            DestinationFile = $DestinationFullName
        }
        Save-OSDProgressFile @splatt

        # Output
        if (Test-Path $DestinationFullName) {
            Get-Item $DestinationFullName
        }
        else {
            Write-Warning "Could not download $DestinationFullName"
            $null
        }
    }
}