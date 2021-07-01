<#
.SYNOPSIS
Stop Progress UI in other or current powershell process

.DESCRIPTION
Stop Progress UI in other or current powershell process

#>
function Stop-OSDProgress {
    [CmdletBinding()]
    Param ()

    $IsRunning = Test-PipeServer
    if ($IsRunning) {
        Write-Verbose "Remove Named Pipe for OSDProgress"
        $clientHash = Connect-PipeServer

        $clientHash.sw.WriteLine("closeServer")

        Stop-PipeCommunication -PipeHash $clientHash
    }
    elseif (Test-UI) {
        Write-Verbose "Close WPF form via Dispatcher"
        $Script:ProgressUI.Form.Dispatcher.Invoke([action] {
                $Script:ProgressUI.BlockClose = $false
                $Script:ProgressUI.Form.close()
                $Script:ProgressUI.IsRunning = $false

            }, "Normal")
    }
    else {
        Write-Warning "OSDProgress already closed or not visible"
    }
}