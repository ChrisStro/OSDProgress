function Test-OSDModule {
    Write-Verbose "Check if OSD Powershell module is installed"
    $OSDModule =  Get-Module osd -ListAvailable
    if ($OSDModule) {
        $true
    }
    else {
        $false
    }
}