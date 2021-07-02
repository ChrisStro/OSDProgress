<#
.SYNOPSIS
Starts Progress UI in current powershell process

.DESCRIPTION
Starts Progress UI in current powershell process

.PARAMETER Window
Progress UI that runs in windowed mode, good for testing/development

.PARAMETER TemplateFile
Enter path to a template file to modify icons and phase messages

.PARAMETER Style
Apply Win10 (default) or Win11 (not finished) layout

.EXAMPLE
Invoke-OSDProgress
# Default behavior

.EXAMPLE
Invoke-OSDProgress -Window -Style Win10
# Windowed progress screen + Windows 11 color scheme

.NOTES
General notes
#>
Function Invoke-OSDProgress {
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
        # Some vars
        ###################################################
        $xamlFile = Join-Path $UIPath "$Style.xaml"
        $preStagedTemplate = Join-Path (Split-Path $env:SystemRoot -Qualifier) "OSDProgressTemplate.psd1"

        # Create synchronised hashtable
        ###################################################
        $syncHash = [hashtable]::Synchronized(@{})
        $syncHash.Runspace = $null
        $syncHash.IsRunning = $true

        # Load unlock password
        ###################################################
        $unlockPwd = Receive-Password

        # Check for prestaged template file in root
        ###################################################
        if (!$PSBoundParameters.ContainsKey('TemplateFile')) {
            if (Test-Path $preStagedTemplate) {
                $TemplateFile = $preStagedTemplate
            }
        }

        $scriptBlock = {
            try {
                # Create synchronised Hashtable
                ###################################################
                [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
                [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

                $AssemblyLocation = Join-Path -Path $UIPath -ChildPath "assembly"
                foreach ($Assembly in (Get-ChildItem $AssemblyLocation -Filter *.dll)) {
                    [System.Reflection.Assembly]::LoadFrom($Assembly.fullName) | Out-Null
                }

                # Load MainWindow
                ###################################################
                $XamlLoader = [System.Xml.XmlDocument]::new()
                $XamlLoader.Load($xamlFile)
                $XamlMainWindow = $XamlLoader

                $Reader = [System.Xml.XmlNodeReader]::new($XamlMainWindow)
                $syncHash.Form = [Windows.Markup.XamlReader]::Load($Reader)

                # Import Template
                ###################################################
                $syncHash.TemplateData = Import-PowerShellDataFile $TemplateFile
                $syncHash.Phase1_Icon = $syncHash.Form.FindName("Phase1_Icon")
                $syncHash.Phase1_Icon.Kind = $syncHash.TemplateData.Phase1.Icon
                $syncHash.Phase2_Icon = $syncHash.Form.FindName("Phase2_Icon")
                $syncHash.Phase2_Icon.Kind = $syncHash.TemplateData.Phase2.Icon
                $syncHash.Phase3_Icon = $syncHash.Form.FindName("Phase3_Icon")
                $syncHash.Phase3_Icon.Kind = $syncHash.TemplateData.Phase3.Icon

                # Load Elements
                ###################################################
                $syncHash.Phase1_Badge = $syncHash.Form.FindName("Phase1_Badge")
                $syncHash.Phase2_Line = $syncHash.Form.FindName("Phase2_Line")
                $syncHash.Phase2_Badge = $syncHash.Form.FindName("Phase2_Badge")
                $syncHash.Phase3_Line = $syncHash.Form.FindName("Phase3_Line")
                $syncHash.Phase3_Badge = $syncHash.Form.FindName("Phase3_Badge")
                $syncHash.Step_Status = $syncHash.Form.FindName("Step_Status")
                $syncHash.Step_Text = $syncHash.Form.FindName("Step_Text")
                $syncHash.Progress_StackPanel = $syncHash.Form.FindName("Progress_StackPanel")
                $syncHash.Progress = $syncHash.Form.FindName("Progress")
                $syncHash.File_Label = $syncHash.Form.FindName("File_Label")
                $syncHash.Unlock = $syncHash.Form.FindName("Unlock")
                $syncHash.Error_Label = $syncHash.Form.FindName("Error_Label")
                $syncHash.Error_StackPanel = $syncHash.Form.FindName("Error_StackPanel")

                # Enable windowed mode
                ###################################################
                $MainWindow = $syncHash.Form.FindName("MainWindow")
                if ($Window.IsPresent) {
                    $MainWindow = $syncHash.Form.FindName("MainWindow")
                    $MainWindow.ResizeMode = "CanResizeWithGrip"
                    $MainWindow.WindowState = "Normal"
                    $MainWindow.UseNoneWindowStyle = "False"
                    $MainWindow.Topmost = "False"
                    $MainWindow.ShowSystemMenuOnRightClick = "true"
                }
                # Set start values
                ###################################################
                $syncHash.Phase2_Line.Opacity = "0"
                $syncHash.Phase3_Line.Opacity = "0"
                $syncHash.Step_Status.Content = $syncHash.TemplateData.Phase1.Content
                $syncHash.Phase = "Phase1"
                $syncHash.BlockClose = $true

                # Unlock eventhandler
                ###################################################
                $syncHash.Unlock.Add_Click{
                    # dev
                    # $pw = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($syncHash.Form, "", "Enter unlock password")
                    # $pw | ConvertTo-Json

                    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalLoginExternal($syncHash.Form, "Unlock OSDProgress", "Only password matters")
                    $pw = $result.Password
                    if ($pw -eq $unlockPwd) {
                        Stop-OSDProgress
                        # $syncHash.Form.close()
                        # $syncHash.IsRunning = $false
                    }
                }

                # On close, block easy escape
                ###################################################
                $syncHash.Form.Add_Closing{
                    if ($syncHash.BlockClose -eq $true) {
                        $_.cancel = $true
                    }
                }

                # $syncHash.Form.Add_Closing( {
                #         param(
                #             [Parameter(Mandatory)][Object]$sender,
                #             [Parameter(Mandatory)][System.ComponentModel.CancelEventArgs]$e
                #         )
                #         $e.Cancel = $true;
                #     } )

                # Add custom key function / develop
                ###################################################
                $MainWindow.add_KeyDown{
                    param
                    (
                        [Parameter(Mandatory)][Object]$sender,
                        [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
                    )
                    if ($e.Key -eq 'F1') {
                        # $window.DialogResult = $true
                        [System.Windows.Forms.MessageBox]::Show("F1 will not happen", "In Development", 0)
                    }

                    if ($e.Key -eq 'F2') {
                        # $window.DialogResult = $false
                        [System.Windows.Forms.MessageBox]::Show("F2 will not happen", "In Development", 0)
                    }
                }

                # Import $syncHash into OSDProgress & Show Form
                ###################################################
                Import-OSDProgress $syncHash
                $syncHash.Form.ShowDialog() | Out-Null
            }
            catch {
                $syncHash.Error = $Error
            }
        }

        # Create backround runspace
        ###################################################
        $rsSplatt = @{
            Name         = "OSDProgress"
            SetVariable  = "Window", "syncHash", "xamlFile", "UIPath", "unlockPwd", "TemplateFile"
            ScriptBlock  = $scriptBlock
            DisposeBlock = $disposeBlock
        }
        $syncHash.Runspace = New-psRunspace @rsSplatt

        Start-Sleep -Milliseconds 500 # add some time to sync hashtable

        $rsError = $syncHash.Error
        if ($rsError) {
            $message = "Error in Runspace :" + $rsError[0].Exception.Message
            throw $message
        }
        $Script:ProgressUI = $syncHash

        # Wait until visible
        ###################################################
        while (-not (Test-UI)) { Start-Sleep -Milliseconds 500 }
    } catch {
        Write-Error $_.Exception.Message
        if ($syncHash.Phase) {
            Stop-OSDProgress
        }
    }
}