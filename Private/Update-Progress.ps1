function Update-Progress {
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

    process {
        $updateHash = [ordered]@{}
        if ($Phase) {
            $ProgressUI.Phase = "Phase" + $Phase
            $updateHash += [ordered]@{
                Progress = @{
                    Value = 0
                }
            }
            $updateHash += switch ($Phase) {
                "2" {
                    [ordered]@{
                        Phase1_Badge = @{
                            Badge           = [Char]8730
                            BadgeBackground = "green"
                        }
                        Step_Status = @{
                            # Content = "Phase : Download Content"
                            Content = $ProgressUI.TemplateData.Phase2.Content
                        }
                        Phase2_Line  = @{
                            Opacity = "1"
                        }
                    }; break
                }
                "3" {
                    [ordered]@{
                        Phase2_Badge = @{
                            Badge           = [Char]8730
                            BadgeBackground = "green"
                        }
                        Step_Status    = @{
                            # Content = "Phase : Post Actions"
                            Content = $ProgressUI.TemplateData.Phase3.Content
                        }
                        Phase3_Line  = @{
                            Opacity = "1"
                        }
                    }; break
                }
                Finish {
                    [ordered]@{
                        Phase3_Badge = @{
                            Badge           = [Char]8730
                            BadgeBackground = "green"
                        }
                        Step_Status   = @{
                            Content = "Setup Completed"
                        }
                    }; break
                }
            }
        }

        if ($Text) {

            Write-Verbose -Message "Setting Step_Text to $Text"
            $updateHash += [ordered]@{
                Step_Text = @{
                    Content = $Text
                }
            }
        }


        if ($DisplayBar) {
            $updateHash += [ordered]@{
                Progress_StackPanel = @{
                    Visibility = "Visible"
                }
            }
        }

        if ($HideBar) {
            $updateHash += [ordered]@{
                Progress_StackPanel = @{
                    Visibility = "Hidden"
                }
            }
        }

        if ($PercentComplete) {

            Write-Verbose -Message "Setting PercentComplete to $PercentComplete"
            $updateHash += [ordered]@{
                Progress = @{
                    Value = $PercentComplete
                }
            }
        }

        if ($DownloadFile) {

            Write-Verbose -Message "Display $DownloadFile as cur downloaded file PercentComplete to $PercentComplete"
            $updateHash += [ordered]@{
                File_Label = @{
                    Content = "$DownloadFile"
                }
            }
        }

        if ($DisplayError) {

            $curPhase = $ProgressUI.Phase
            $curBadge = "$curPhase" + "_Badge"
            $updateHash = [ordered]@{
                Error_Label      = @{
                    Content = $DisplayError
                }
                Error_StackPanel = @{
                    Visibility = "Visible"
                }
                $curBadge        = @{
                    Badge           = "!"
                    BadgeBackground = "red"
                }
            }
        }

        # Output
        ###################################################
        Write-Verbose "Updated values : $($updateHash | ConvertTo-Json)"

        # Update Form via dispatcher
        ###################################################
        if ($updateHash) {
            foreach ($item in $updateHash.GetEnumerator()) {
                foreach ($value in $item.value) {
                    if ($value -is [hashtable]) {
                        $value.GetEnumerator() | ForEach-Object {
                            $ProgressUI.Form.Dispatcher.Invoke([action] {
                                    $ProgressUI.$($item.Name).$($_.Key) = $_.Value
                                }, "Normal")
                        }
                    }
                    else {
                        $ProgressUI.$($item.Name).$value
                    }
                }
            }
        }
    }
}
