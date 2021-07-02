<#
.SYNOPSIS
Start OSDProgress in current process and create an Named Pipe for inter-process communication

.DESCRIPTION
Start OSDProgress in current process and create an Named Pipe for inter-process communication

.PARAMETER Window
Start OSDProgress in windowed mode, useful for dev of custom functions

.PARAMETER TemplateFile
Enter path to a template file to modify icons and phase messages

.PARAMETER Style
Apply Win10 (default) or Win11 (not finished) layout

#>
function Start-OSDProgress {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]$Window,

        [Parameter()]
        [ValidateSet("Win10", "Win11")]
        [string]$Style = "Win10",

        [Parameter()]
        [string]$TemplateFile = $DefaultTemplate
    )

    try {
        # Check if OSDProgressServer is running
        ###################################################
        $IsRunning = Test-PipeServer
        if ($IsRunning) {
            Write-Warning "OSDProgressServer already running, use 'Stop-OSDProgress' before starting new server pipe"
            break
        }

        # Start OSDProgress in current process
        ###################################################
        Write-Host -ForegroundColor Magenta "Starting Progress Screen"
        Invoke-OSDProgress @PSBoundParameters

        # Create Named Pipe server loop
        ###################################################
        Write-Host "Create Named Pipe to update OSDProgress from different process via " -NoNewline
        Write-Host -ForegroundColor Green "'Update-OSDProgress'"
        $keepRunning = $true
        while ($keepRunning) {

            # Create named pipe server loop
            ###################################################
            $serverHash = Start-PipeServer
            Write-Host -ForegroundColor "cyan" "Server waiting for next command"
            $serverHash.server.WaitForConnection()

            $receive = $serverHash.sr.ReadLine()
            "Received command : $receive"
            if ($receive -eq "closeServer") {
                $keepRunning = $false
            }
            else {
                $receive | Invoke-Expression
            }

            Stop-PipeCommunication -PipeHash $serverHash
        }
        Stop-OSDProgress
    }
    catch {
        $_.Exception.Message
        Stop-OSDProgress
    }
}
