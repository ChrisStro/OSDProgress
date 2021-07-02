Watch-OSDCloudProvisioning {
    Write-Host -ForegroundColor Cyan "Hey this script running an OSD Cloud ZTI Deployment while displaying a MahApps.Metro progress Window"

    #Start OSDCloud ZTI, Update Module first
    Update-OSDProgress -Text "Starting OSDCloud PreAction stuff..." # output to UI
    Write-Host  -ForegroundColor Cyan "Starting OSDCloud PreAction stuff..." # output to console
    Start-Sleep -Seconds 3
    Update-OSDProgress -Text "Updating & Import the awesome OSD PowerShell Module"
    Install-Module OSD -Force
    Import-Module OSD -Force
    Update-OSDProgress -Text " " # hide first text

    Start-OSDCloud -OSBuild 20H2 -OSEdition Pro -ZTI

    #Anything I want  can go right here and I can change it at any time since it is in the Cloud!!!!!
    Update-OSDProgress -Text "Starting OSDCloud PostAction stuff..."
    Write-Host  -ForegroundColor Cyan "Starting OSDCloud PostAction stuff..."
    Start-Sleep -Seconds 5
    Update-OSDProgress -Text " " # hide first text

    # lets throw an error, just for fun
    #Update-OSDProgress -DisplayError "Custom error message, pls unlock screen!"

    #Restart from WinPE
    Update-OSDProgress -Text "Reboot in 20 seconds"
    Start-Sleep -Seconds 20
    wpeutil reboot
}