<#
.SYNOPSIS
Update running progress screen

.DESCRIPTION
Update running progress screen

.PARAMETER Phase
Switch between 3 phases

.PARAMETER Text
Display small text under current phase label

.PARAMETER PercentComplete
Update current percent in progressbar (make visibile via [-DisplayBar])

.PARAMETER DownloadFile
Displays filename in file label

.PARAMETER DisplayBar
Make progressbar visible in progress ui

.PARAMETER HideBar
Hide Progressbar in progress ui

.PARAMETER DisplayError
Displays an error message in progress ui

.EXAMPLE
Update-OSDProgress -Phase 2

# Switched to Phase 2

.EXAMPLE
Update-OSDProgress -DisplayBar -DownloadFile "file.dat"

# Make progressbar visible and displays the current downloaded file

.EXAMPLE
Update-OSDProgress -PercentComplete 33

# Update progressbar to 33 %

#>
function Update-OSDProgress {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, ParameterSetName = "Phase")]
        [ValidateSet("2", "3", "Finish")]
        [string]$Phase,

        [Parameter(Position = 1, ParameterSetName = "Phase")]
        [string]$Text,

        [Parameter(ValueFromPipeline, ParameterSetName = "Download")]
        [ValidateRange(1 , 100)]
        [int]$PercentComplete,

        [Parameter(ParameterSetName = "Download")]
        [string]$DownloadFile,

        [Parameter(ParameterSetName = "Download")]
        [switch]$DisplayBar,

        [Parameter(ParameterSetName = "Download")]
        [switch]$HideBar,

        [Parameter(ParameterSetName = "Display-Error")]
        [string]$DisplayError
    )

    begin {
        # Check mode
        ###################################################
        $IsRunning = Test-PipeServer
        if ($IsRunning) {
            Write-Verbose "Send Update via Servermode"
        } else {
            Write-Verbose "Send Update via Processmode"
            Stop-ProgressDone
            Stop-NoUI
        }
    }

    process {
        if ($IsRunning) {
            Update-ProgressServer @PSBoundParameters
        } else {
            Update-Progress @PSBoundParameters
        }
    }
}