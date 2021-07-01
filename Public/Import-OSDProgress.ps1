<#
.SYNOPSIS
Function for importing the current OSDProgress status into a new runspace

.DESCRIPTION
Function for importing the current OSDProgress status into a new runspace

.PARAMETER SynHash
[SyncHashtable] which includes current OSDProgress state

#>
function Import-OSDProgress {
    param (
        [Parameter(Mandatory)]
        $SynHash
    )
    if ($Script:ProgressUI.Count -eq 0) {
        $Script:ProgressUI = $syncHash
    }
    else {
        Write-Verbose "Import is only supported if empty"
    }
}