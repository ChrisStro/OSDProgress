function Watch-OSDCloudProvisioning {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$OSDCloudScript,

        [Parameter()]
        [Switch]$Window,

        [Parameter()]
        [ValidateSet("Win10", "Win11")]
        [string]$Style = "Win10",

        [Parameter()]
        [string]$TemplateFile = $DefaultTemplate
    )

    begin {
        try {
            # Start screen first
            ###################################################
            if (-not(Test-PipeServer)) {
                Write-Verbose "No Named Pipe server running, starting OSDProgress in same process"
                $PSBoundParameters.Remove('OSDCloudScript') | Out-Null
                Invoke-OSDProgress @PSBoundParameters
            }

            # Prepare Environment
            ###################################################
            $OSDModuleInstalled = Test-OSDModule
            if (!$OSDModuleInstalled) {
                throw "Could not detect David Saguras OSD Module"
            }

            # Override 'Save-WebFile' function of OSD module
            ###################################################
            Register-OSDOverride

            # Start monitoring OSDCloud status
            ###################################################
            $winpeLog = Join-Path $env:windir "system32\winpeLog.log"
            Watch-OSDCloudLog -WinPELog $winpeLog

        } catch {
            $message = $_.Exception.Message
            Update-OSDProgress -DisplayError $message
        }
    }

    process {
        try {
            # Invoke passed Scriptblock
            ###################################################
            . $OSDCloudScript

            # Finaly done
            ###################################################
            Update-OSDProgress -Phase Finish

        } catch {
            $message = $_.Exception.Message
            Update-OSDProgress -DisplayError $message
        }
    }

    end {
        Stop-Transcript | Out-Null
        Unregister-OSDOverride
    }
}