<#
.SYNOPSIS
Raise event in main thread of powershell process

.DESCRIPTION
Raise event in main thread of powershell process

.PARAMETER SourceIdentifier
Name of SourceIdentifier of event subscriber/eventhandler

.PARAMETER SenderObj
Sender object parsed to eventhandler in mainthread

.PARAMETER SourceArgs
Custom args object(s) parsed to eventhandler in mainthread

.PARAMETER MessageData
MessageData object parsed to eventhandler in mainthread

.EXAMPLE
Invoke-psRunspaceEvent -SourceIdentifier stop.Translog -SenderObj $result -MessageData "Transcript done"
#>
function Invoke-psRunspaceEvent ($SourceIdentifier, $SenderObj, $SourceArgs, $MessageData) {
    if ($SyncHost) {
        $SyncHost.Host.Runspace.Events.GenerateEvent($SourceIdentifier, $SenderObj, $SourceArgs, $MessageData)
    }
    else {
        Write-Warning "No CallbackBlock passed into current runspace"
    }
}