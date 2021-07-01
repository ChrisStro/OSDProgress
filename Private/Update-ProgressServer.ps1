function Update-ProgressServer {
    [CmdletBinding()]
    Param (
        [Parameter()]
        [ValidateSet("2", "3", "Finish")]
        $Phase,

        [Parameter()]
        [string]$Text,

        [Parameter(ValueFromPipeline)]
        [int]$PercentComplete,

        [Parameter()]
        [string]$DownloadFile,

        [Parameter()]
        [switch]$DisplayBar,

        [Parameter()]
        [switch]$HideBar,

        [Parameter()]
        [string]$DisplayError
    )

    begin {
        # Precheck/Connect
        ###################################################
        $IsRunning = Test-PipeServer
        if (!$IsRunning) {
            Write-Warning "no pipe for OSDProgress found, run 'Start-OSDProgress' first in different process"
            break
        }
        $clientHash = Connect-PipeServer
    }

    process {

        # Build/Send command
        ###################################################
        if ($CloseServer.IsPresent) {
            $command = "closeServer"
        }
        else {

            $InlineParam = ''
            foreach ($item in $PSBoundParameters.GetEnumerator()) {

                $value = $item.value
                $bool = $null # ref var to safely check boolean
                if ($item.value -is [string]) {
                    $value = "`"" + $item.value + "`""
                }
                if ([bool]::TryParse($item.Value, [ref]$bool)) {
                    $value = $null
                }

                $InlineParam += " -$($item.Key) " + $value
            }
            $command = "Update-Progress$InlineParam"
        }
        $clientHash.sw.WriteLine($command)
    }

    End {
        Stop-PipeCommunication -PipeHash $clientHash
    }
}