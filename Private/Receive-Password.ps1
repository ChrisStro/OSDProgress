function Receive-Password {
    $pwFile = Join-Path $env:windir "System32\osdprogress.pass"
    if (Test-Path $pwFile) {
        Get-Content $pwFile
    }
    else {
        # Default Password
        #########################################
        "unlock"
    }
}