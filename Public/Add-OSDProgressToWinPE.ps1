<#
.SYNOPSIS
Add OSDProgress settingsto WinPE image

.DESCRIPTION
Add OSDProgress to WinPE image

.PARAMETER BootWim
Enter wim file to modify

.PARAMETER OSDCloud
Runs modification against current OSDCloud workspace

.PARAMETER UnlockPass
Enter password for unlock button of OSDProgress

.PARAMETER UnattendXML
Enable OSDProgress start via unattend.xml (Start-OSDProgress) on WinPE boot

.PARAMETER WinpeshlIni
Enable OSDProgress start via winpeshl.ini (Start-OSDProgress) on WinPE boot, starts earlier than unattend.xml

.PARAMETER RemoveUnattendXML
Remove unattend.xml from wim file

.PARAMETER RemoveWinpeshlIni
Remove unattend.xml and winpeshl.ini from wim file

.PARAMETER RemoveAll
Remove unattend.xml, winpeshl.ini and password file from wim file

.EXAMPLE
Add-OSDProgressToWinPE -OSDCloud -UnlockPass 'mysecret' -WinpeshlIni

.EXAMPLE
Add-OSDProgressToWinPE -BootWim c:\WinPe\customWinPE.wim -UnlockPass 'mysecret' -UnattendXML

.NOTES
Still in dev, breaking changes could happen
#>
function Add-OSDProgressToWinPE {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "BootWim-Unattend")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "BootWim-Winpeshl")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "BootWim-RemoveAll")]
        [string]$BootWim,

        [Parameter(Mandatory, Position = 0, ParameterSetName = "OSDCloud-Unattend")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "OSDCloud-Winpeshl")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "OSDCloud-RemoveAll")]
        [switch]$OSDCloud,

        [Parameter(Position = 1)]
        [string]$UnlockPass,

        [Parameter(ParameterSetName = "BootWim-Unattend")]
        [Parameter(ParameterSetName = "OSDCloud-Unattend")]
        [switch]$UnattendXML,

        [Parameter(ParameterSetName = "BootWim-Winpeshl")]
        [Parameter(ParameterSetName = "OSDCloud-Winpeshl")]
        [switch]$WinpeshlIni,

        [Parameter(ParameterSetName = "BootWim-Winpeshl")]
        [Parameter(ParameterSetName = "OSDCloud-Winpeshl")]
        [switch]$RemoveUnattendXML,

        [Parameter(ParameterSetName = "BootWim-Unattend")]
        [Parameter(ParameterSetName = "OSDCloud-Unattend")]
        [switch]$RemoveWinpeshlIni,

        [Parameter(ParameterSetName = "BootWim-RemoveAll")]
        [Parameter(ParameterSetName = "OSDCloud-RemoveAll")]
        [switch]$RemoveAll
    )

    begin {
        if ($OSDCloud) {
            if (!(Test-OSDModule)) {
                Write-Warning "Could not detect David Seguras OSD Module"
                break
            }

            $curWorkspace = Get-OSDCloud.workspace
            if (!$curWorkspace) {
                Write-Warning "No workspace set, run New-OSDCloud.workspace first!"
                break
            }

            $bootWim = Join-Path $curWorkspace "Media\sources\boot.wim"
        }
        if ($PSCmdlet.ParameterSetName -eq "BootWim") {
            $bootWim = Get-Item $BootWim -ErrorAction Stop
        }

        $unattendContent = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
        <Display>
            <ColorDepth>32</ColorDepth>
            <HorizontalResolution>1024</HorizontalResolution>
            <RefreshRate>60</RefreshRate>
            <VerticalResolution>768</VerticalResolution>
        </Display>
        <RunSynchronous>
            <RunSynchronousCommand wcm:action="add">
                <Description>Start OSDProgress</Description>
                <Order>1</Order>
                <Path>cmd.exe /c start powershell -noe -nol -nop -c Start-OSDProgress</Path>
            </RunSynchronousCommand>
        </RunSynchronous>
    </component>
</settings>
</unattend>
'@
        $winpeshlContent = @'
[LaunchApps]
#cmd.exe,/c start powershell -nop -nol -win h -c Start-OSDProgress
powershell.exe,-nop -nol -win h -c "start 'powershell.exe' '-nop -nol -win h -c Start-OSDProgress'
powershell.exe,-nop -nol -win h -c start-sleep 5
cmd.exe,/k startnet.cmd
'@
    }

    process {
        try {
            $mountPoint = Mount-MyWindowsImage -ImagePath $bootWim -Index 1
            $unattendFile = Join-Path $mountPoint.Path "unattend.xml"
            $winpeshlFile = Join-Path $mountPoint.Path "Windows\System32\winpeshl.ini"
            $winpePSModulePath = Join-Path $mountPoint.Path "Program Files\WindowsPowerShell\Modules"
            $unlockFile = Join-Path $mountPoint.Path "Windows\system32\osdprogress.pass"

            if ($PSBoundParameters.ContainsKey('BootWim')) {
                Write-Verbose "Save OSDProgress module to wim file"
                Save-Module -Name OSDProgress -Path $winpePSModulePath -Force -Confirm:$false
            }
            if ($UnlockPass) {
                $splatt = @{
                    FilePath = $unlockFile
                    Encoding = "ascii"
                }
                if (Test-Path $unlockFile) {
                    Write-Warning "Password file present, replace?"
                    $splatt.Confirm = $true
                }
                $UnlockPass | Out-File @splatt
            }
            if ($UnattendXML) {
                $splatt = @{
                    FilePath = $unattendFile
                    Encoding = "ascii"
                }
                if (Test-Path $unattendFile) {
                    Write-Warning "unattend.xml file present, replace?"
                    $splatt.Confirm = $true
                }
                $unattendContent | Out-File @splatt
            }
            if ($WinpeshlIni) {
                $splatt = @{
                    FilePath = $winpeshlFile
                    Encoding = "ascii"
                }
                if (Test-Path $winpeshlFile) {
                    Write-Warning "winpeshl.ini file present, replace?"
                    $splatt.Confirm = $true
                }
                $winpeshlContent | Out-File @splatt
            }
            if ($RemoveUnattendXML -or $RemoveAll) {
                if (Test-Path $unattendFile) {
                    Remove-Item $unattendFile
                } else {
                    Write-Warning "No unattend file present"
                }
            }
            if ($RemoveWinpeshlIni -or $RemoveAll) {
                if (Test-Path $winpeshlFile) {
                    Remove-Item $winpeshlFile
                } else {
                    Write-Warning "No winpeshl.ini present"
                }
            }
            if ($RemoveAll) {
                if (Test-Path $unlockFile) {
                    Remove-Item $unlockFile
                } else {
                    Write-Warning "No password file present"
                }
            }
            $disSplatt = @{ Save = $true }

        } catch {
            $message = $_.Exception.Message
            Write-Error $message
            $disSplatt = @{Discard = $true }
        }
    }

    end {
        if ($mountPoint) {
            $mountPoint | Dismount-MyWindowsImage @disSplatt

            # Create new OSDCloud ISO
            ###################################################
            if (($PSCmdlet.ParameterSetName -like "OSDCloud*") -and ($disSplatt.Save -eq $true)) {
                New-OSDCloud.iso
            }
        }
    }
}