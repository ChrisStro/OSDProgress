function Watch-OSDCloudLog {
    [CmdletBinding()]
    param (
        $WinPELog
    )

    process {

        $syncHash = $Script:ProgressUI

        # Start Transcript in current runspace
        ###################################################
        Start-Transcript $WinPELog | Out-Null

        $scriptBlock = {

            # Import synchash
            ###################################################
            Import-OSDProgress $syncHash

            # Wait for end of first phase
            ###################################################
            $phase2String = "Enable High Performance Power Plan"
            $phase2Action = {
                Update-OSDProgress -Phase 2
            }
            Read-OSDLog $WinPELog $phase2String $phase2Action

            # Wait for end of second phase
            ###################################################
            $phase3String = "Expand-WindowsImage"
            $phase3Action = { Update-OSDProgress -Phase 3 }
            Read-OSDLog $WinPELog $phase3String $phase3Action
        }

        New-psRunspace -ScriptBlock $scriptBlock -SetVariable "WinPELog", "syncHash" | Out-Null
    }
}
<#
function Watch-OSDCloudLog {
    [CmdletBinding()]
    param (
        $WinPELog
    )

    process {

        $syncHash = $Script:ProgressUI

        # Start Transcript in current runspace
        ###################################################
        Start-Transcript $WinPELog | Out-Null

        $scriptBlock = {

            # Import synchash
            ###################################################
            Import-OSDProgress $syncHash

            # Wait for end of first phase
            ###################################################
            $phase2String = "Enable High Performance Power Plan"
            $phase2Action = {
                Update-OSDProgress -Phase 2
                Invoke-psRunspaceEvent -SourceIdentifier "OSDCloud.StopWinPETranscript"
            }
            Read-OSDLog $WinPELog $phase2String $phase2Action

            # Wait for OSDCloud Transcript
            ###################################################
            while (-not (Test-Path C:\OSDCloud\Logs\*.log)) {
                Start-Sleep -Milliseconds 200
            }
            $newTranslogFile = Get-ChildItem C:\OSDCloud\Logs\*.log | Select-Object -ExpandProperty FullName

            # Wait for end of second phase
            ###################################################
            $phase3String = "Expand-WindowsImage"
            $phase3Action = { Update-OSDProgress -Phase 3 }
            Read-OSDLog $newTranslogFile $phase3String $phase3Action
            # Read-OSDLog $WinPELog $phase3String $phase3Action
        }

        $callbackBlock = {
            Stop-Transcript | Out-Null
        }

        # New-psRunspace -ScriptBlock $scriptBlock -SetVariable "WinPELog","syncHash" | Out-Null
        New-psRunspace -ScriptBlock $scriptBlock -SetVariable "WinPELog","syncHash" -CallbackName "OSDCloud.StopWinPETranscript"  -CallbackBlock $callbackBlock | Out-Null
    }
}
#>