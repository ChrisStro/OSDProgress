<#
.SYNOPSIS
Function to monitor OSDCloud progress with OSDProgress

.DESCRIPTION
Function to monitor OSDCloud progress with OSDProgress

.PARAMETER OSDCloudScript
Enter your OSDCloud script content here

.PARAMETER Window
Progress UI that runs in windowed mode, good for testing/development

.PARAMETER Style
Apply Win10 (default) or Win11 (not finished) layout

.PARAMETER TemplateFile
Enter path to a template file to modify icons and phase messages

.EXAMPLE
Watch-OSDCloudProvisioning { Start-OSDCloud -OSBuild 20H2 -OSEdition Pro -ZTI }

# Really simple example

#>
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
                throw "Could not detect David Seguras OSD Module"
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