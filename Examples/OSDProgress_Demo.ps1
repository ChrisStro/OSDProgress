# Sample script for available function
###################################################


# Start OSDProgress in process mode
###################################################
Invoke-OSDProgress -Window #-Style # for Win11 Style

# Complete phase 1 and mov to next phase
###################################################
Start-Sleep 4 # Simulate doing stuff
Update-OSDProgress -Phase 2

# Display progress bar and add some progress
###################################################
Update-OSDProgress -DisplayBar
Start-Sleep 3
Update-OSDProgress -PercentComplete 33 -DownloadFile "DownloadedFile.dat"
Start-Sleep 3
Update-OSDProgress -PercentComplete 66
Start-Sleep 3
Update-OSDProgress -PercentComplete 100
Start-Sleep 1
Update-OSDProgress -DownloadFile " " -HideBar
# Note: You dont have to do this manualy, the Save-OSDProgressFile can be used


# Complete phase 2 and mov to next phase
###################################################
Start-Sleep 4 # Simulate doing stuff
Update-OSDProgress -Phase 3

Update-OSDProgress -DisplayError "Lets throw an Error, just for fun"
Update-OSDProgress -Text "System reboots in 20s"

Read-Host -Prompt "Press any key to close OSDProgress"
Stop-OSDProgress
