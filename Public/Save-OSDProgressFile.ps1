<#
.SYNOPSIS
Download webfiles via Streamreader in background thread and updates progressbar in mainthread

.DESCRIPTION
Download webfiles via Streamreader and updates progressbar every 4%

.PARAMETER URL
WebURL of download file

.PARAMETER File
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Save-OSDProgressFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$URL,

        [Parameter(Mandatory)]
        [string]$DestinationFile
    )

    Begin {
        # Check if UI is running
        ###################################################
        #Stop-NoUI
    }

    Process {
        try {
            # Tracking variable
            ###################################################
            $syncHash = [hashtable]::Synchronized(@{})

            # Check destination
            ###################################################
            $fileName = $DestinationFile | Split-Path -Leaf
            if ((Test-UI) -or (Test-PipeServer)) {
                Write-Verbose "Display Progressbar for $fileName"
                Update-OSDProgress -DisplayBar -DownloadFile $fileName
            }

            if ($DestinationFile -match '^\.\\') {
                $DestinationFile = Join-Path (Get-Location -PSProvider "FileSystem") ($DestinationFile -Split '^\.')[1]
            }
            if ($DestinationFile -and !(Split-Path $DestinationFile)) {
                $DestinationFile = Join-Path (Get-Location -PSProvider "FileSystem") $DestinationFile
            }
            if ($DestinationFile) {
                $fileDirectory = $([System.IO.Path]::GetDirectoryName($DestinationFile))
                if (!(Test-Path($fileDirectory))) {
                    [System.IO.Directory]::CreateDirectory($fileDirectory) | Out-Null
                }
            }

            # Backround block | Download without interruption
            ###################################################
            $sb = {
                try {
                    $ErrorActionPreference = 'Stop'

                    # Create streamreader/streamwriter
                    ###################################################
                    $request = [System.Net.HttpWebRequest]::Create($URL)
                    $response = $request.GetResponse()

                    if ($response.StatusCode -eq 401 -or $response.StatusCode -eq 403 -or $response.StatusCode -eq 404) {
                        throw "Remote file either doesn't exist, is unauthorized, or is forbidden for '$URL'."
                    }

                    [long]$fullSize = $response.ContentLength
                    $fullSizeMB = $fullSize / 1024 / 1024

                    [byte[]]$buffer = new-object byte[] 1048576
                    [long]$total = [long]$count = 0

                    # create reader / writer
                    $reader = $response.GetResponseStream()
                    $writer = new-object System.IO.FileStream $DestinationFile, "Create"

                    # Start download
                    ###################################################
                    $lastPercent = 0
                    do {
                        $count = $reader.Read($buffer, 0, $buffer.Length)
                        $writer.Write($buffer, 0, $count)

                        $total += $count
                        $totalMB = $total / 1024 / 1024
                        $percent = $totalMB / $fullSizeMB
                        [int]$percentComplete = $percent * 100

                        # Throttle var updates
                        ###################################################
                        if ($fullSize -gt 0 -and ($percentComplete % 4 -eq 0) -and ($percentComplete -ne $lastPercent)) {
                            $syncHash.cur = [int]$percentComplete
                            $lastPercent = $percentComplete
                        }

                    } while ($count -gt 0)
                }

                catch {
                    $syncHash.error = $_
                }

                finally {
                    # Cleanup/Dispose
                    ###################################################
                    if ($reader) { $reader.Close() }
                    if ($writer) { $writer.Flush(); $writer.Close() }
                }
            }

            # Invoke new runspace
            ###################################################
            $rsSplatt = @{
                Name        = "OSDProgressFile.$filename"
                SetVariable = "filename", "url", "DestinationFile", "syncHash"
                ScriptBlock = $sb
            }
            $rs = New-psRunspace @rsSplatt

            # Wait for runspace | WPF/Console output in main thread
            ###################################################
            Write-Host -NoNewline -ForegroundColor DarkGray ("#" * 29)
            Write-Host -NoNewline -ForegroundColor Cyan " $filename "
            Write-Host -ForegroundColor DarkGray ("#" * 29)
            $lastPercent = 0
            while ($lastPercent -ne 100) {
                if ($syncHash.error) {
                    throw $syncHash.error
                }

                # Throttle output
                ###################################################
                [int]$curPercent = $syncHash.cur
                if (($curPercent -ne $lastPercent) -and ($curPercent % 4 -eq 0)) {
                    if ((Test-UI) -or (Test-PipeServer)) {
                        Update-OSDProgress -PercentComplete $curPercent
                    }
                    Write-Host -NoNewLine "`rDownload $fileName, complete : [$($curPercent.ToString("##0.00").PadLeft(6)) %]"
                    if ($curPercent -eq 100) { Write-Host "`n" }
                    $lastPercent = $curPercent
                    Start-Sleep -Seconds 1
                }
            }
        }

        catch {
            $ExeptionMsg = $_.Exception.Message
            Write-Host "Download breaks with error : $ExeptionMsg"
        }

        finally {
            # Cleanup if canceled via Strg+C
            ###################################################
            if ($rs.RunspaceAvailability -eq "Busy") {
                $rs.Closeasync()
                $rs.Dispose()
            }
        }
    }

    End {
        Update-OSDProgress -HideBar -DownloadFile " "
    }
}