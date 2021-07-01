<#
.SYNOPSIS
Start scriptblock in background runspace, which will disposed when finished

.DESCRIPTION
Start scriptblock in background runspace, which will disposed when finished

.PARAMETER SetVariable
Variables to be parsed in runspace

.PARAMETER ScriptBlock
Scriptblock running in runspace

.PARAMETER CallbackBlock
Scriptblock triggert by events via Invoke-psRunspaceEvent

.PARAMETER $CallbackName
Name of sourceIdentifier for CallbackBlock parameter

.PARAMETER DisposeBlock
Scriptblock for custom actions on dispose

.NOTES
added in version 0.0.1
#>
function New-psRunspace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=1,ParameterSetName="Scriptblock")]
        [Parameter(Mandatory,Position=1,ParameterSetName="CallBack")]
        [scriptBlock]$ScriptBlock,

        [Parameter(Position=2,ParameterSetName="Scriptblock")]
        [Parameter(Position=2,ParameterSetName="CallBack")]
        [string[]]$SetVariable,

        [Parameter(Position=3,ParameterSetName="Scriptblock")]
        [Parameter(Position=3,ParameterSetName="CallBack")]
        [string]$Name,

        [Parameter(Mandatory,ParameterSetName="CallBack",Position=3)]
        [scriptBlock]$CallbackBlock,

        [Parameter(Mandatory,ParameterSetName="CallBack",Position=4)]
        [string]$CallbackName,

        [Parameter(Position=5,ParameterSetName="Scriptblock")]
        [Parameter(Position=5,ParameterSetName="CallBack")]
        [scriptBlock]$DisposeBlock
    )

    # Create New Runspace
    #########################################
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions = "ReuseThread"
    if ($Name) { $rs.Name = $Name }
    $rs.Open() | Out-Null

    foreach ($varName in $SetVariable) {
        $v = (Get-Variable -Name $varName).Value

        $rs.SessionStateProxy.SetVariable($varName, $v)
    }

    # Add Callback
    #########################################
    if ($CallbackBlock) {
        Register-EngineEvent -SourceIdentifier $CallbackName -Action $CallbackBlock

        $SyncHost = [Hashtable]::Synchronized(@{})
        $SyncHost.Host = $Host
        $rs.SessionStateProxy.SetVariable('SyncHost', $SyncHost)

    }
    $ps = [PowerShell]::Create().AddScript($ScriptBlock)
    $ps.Runspace = $rs
    $ps.BeginInvoke() | Out-Null

    # Create Powershell Instance
    #########################################
    $ps = [PowerShell]::Create().AddScript($ScriptBlock)
    $ps.Runspace = $rs
    $ps.BeginInvoke() | Out-Null

    # Cleanup Eventhandler
    #########################################
    $MessageData = @{}
    if ($DisposeBlock) {
        $MessageData.DisposeBlock = $DisposeBlock
    }
    if ($CallbackName) {
        $MessageData.CallbackName = $CallbackName
    }

    Register-ObjectEvent -InputObject $rs -EventName 'AvailabilityChanged' -Action {
        if ($Sender.RunspaceAvailability -eq "Available") {

            # Invoke Dispose Block
            #########################################
            $sb = $event.MessageData.DisposeBlock
            if ($sb) {
                $sb.invoke()
            }

            # Cleanup callback
            #########################################
            $CallbackName = $event.MessageData.CallbackName
            if ($CallbackName) {
                Get-EventSubscriber -SourceIdentifier $CallbackName | Unregister-Event
            }

            $Sender.Closeasync()
            $Sender.Dispose()
        }
    } -MessageData $MessageData | Out-Null

    return $rs
}