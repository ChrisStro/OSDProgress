<#
.SYNOPSIS
Monitoring logfiles for matches on strings and call actions

.DESCRIPTION
Monitoring logfiles for matches on strings and call actions

.PARAMETER LogFile
Logfile to monitor

.PARAMETER SearchString
Lookupstring

.PARAMETER Execution
Call scriptblock on match

.EXAMPLE
Read-OSDLog c:\OSD.Log "Download finished" { Update-OSDProgress -Phase 3 }

#>
function Read-OSDLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 1)]
        [string]$LogFile,

        [Parameter(Mandatory, Position = 2)]
        [string]$SearchString,

        [Parameter(Mandatory, Position = 3)]
        [ScriptBlock]$Execution

    )

    do {
        if (Test-Path $logFile) {
            $Line = Get-Content -Path $logFile -Tail 1
            if ($Line -like "*$SearchString*") {
                $Execution.Invoke()
            }
        }
    } until ($Line -like "*$SearchString*")
}

# function Read-OSDLog {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory,ValueFromPipeline,Position=1)]
#         [string]$logFile,

#         [Parameter(Mandatory,Position=2)]
#         [string]$SearchString,

#         [Parameter(Mandatory,Position=3)]
#         [ScriptBlock]$Execution
#     )

#     try {

#         Get-Content $logFile -Tail 1 -Wait | ForEach-Object {
#             if ($_ -like "*$SearchString*") {
#                 $Execution.Invoke()
#                 break
#             }
#         }
#     }
#     catch {
#         $_.Exception.Message
#     }
# }