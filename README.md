
### OSDProgress Module

-----

* [Description](#description)
* [How it works](#how-it-works)
    * [General](#general)
    * [Modes](#modes)
        * [Server](#server-mode)
        * [Process](#server-mode)
* [Quickstart](#quickstart)
    * [Installation](#installation)
    * [OSDCloud](#osdcloud)
        * [Add Module to Winpe](#add-to-winpe)
        * [Use existing OSDCloud script](#use-existing-osdcloud-script)
* [Display](#display)
    * [Style](#style)
    * [Window](#window)
    * [Icons](#icons)
* [Unlock](#unlock)
* [Additional Functions](#additional-functions)
    * [Read-OSDLog](#read-osdlog)
    * [Import-OSDProgress](#import-osdprogress)
    * [Get-OSDProgress](#get-osdprogress)
    * [Add-OSDProgressToWinPE](#add-osdprogresstowinpe)
    * [New-OSDProgressTemplate](#new-osdprogresstemplate)
* [Important to Know](#important-to-know)
* [Known issues](#known-issues)


# Description

OSDProgress is a PowerShell Gallery module to display a Lightweight  progress screen during deployments or other installation. Primary intention was to give [David Seguras OSDCloud Module](https://osdcloud.osdeploy.com/) a Windows like progress screen,without the need of any code modification to Davids module.But you can use this module easily in any situation where you need some kind of progress visualization to notify your end users.

# How it works
## General

1. You start the 3 phase progress screen either with `Invoke-OSDProgress` or `Start-OSDProgress` (more on that later). This will start the progress screen in a background runspace. Main runspace and background runspace communicate using a synchronized hashtable
2.  Since the main thread is available, the progress screen can be updated using the `Update-OSDProgress` function
3.  Download of web files can be done via `Save-OSDProgressFile` function, the progress bar appears and is updating every 4%
4. The phases are switched via `Update-OSDProgress` with the `-Phase` parameter
5. Stop the progress screen with the unlock icon or with `Stop-OSDProgress`

## Modes
### Process-Mode
Starting and updating are carried out in the same Powershell process. Starting OSDProgress with `Invoke-OSDProgress` is useful when all progress updates are done from start to finish in a Powershell process.

### Server-Mode
When `Start-OSDProgress` is used to start the progress screen, a named piped is created and the current Powershell process enters an infinite loop receiving commands to refresh the progress screen.
Since this moment, the progress screen can be updated using various Powershell processes / scripts.
This is perfect if you have multiple scripts in your solution that run one after the other or if you want to start the screen early and hide something in the background
(OSDProgress also do this if you add OSDProgress via winpeshl.ini to your boot images)

[Note: `Update-OSDProgress` will always prefer the progress screen spawned by `Start-OSDProgress`, this is important to know if multiple instances of OSDProgress are active]

# Quickstart

## Installation
Install from [Powershell Gallery](https://www.powershellgallery.com/packages/OSDProgress)!
```powershell
Install-Module OSDProgress
```

## OSDCloud

### Add to WinPE
Add the installed OSDProgress module to your WinPE using `Edit-OSDCloud.winpe` function of the OSD Module

```powershell
Edit-OSDCloud.winpe -PSModuleCopy OSDProgress
```
### Use existing OSDCloud script
Simply wrap your existing OSDCloud script into the scriptblock of the 'Watch-OSDCloudProvisioning' function :

```powershell
Watch-OSDCloudProvisioning {
    Write-Host -ForegroundColor Cyan "Hey this script running an OSD Cloud ZTI Deployment while displaying a MahApps.Metro progress Window"

    Write-Host  -ForegroundColor Magenta "Doing stuff before"

    Start-OSDCloud -OSBuild 20H2 -OSEdition Pro -ZTI

    Write-Host  -ForegroundColor Magenta "Doing stuff after"
}
```
[Note: little example scripts can be found here](https://github.com/ChrisStro/OSDProgress/tree/main/Examples)

If `Start-OSDProgress` is used before `Watch-OSDCloudProvisioning` it will update the prestarted progress screen, else it will automatically spawn a new using `Invoke-OSDProgress`

# Display
`Invoke-OSDProgress`, `Watch-OSDCloudProvisioning` and `Start-OSDProgress` have some parameters to change the layout of the progress screen

## Style
`-Style` parameter for a Windows 10 or Windows 11 (not realy finished yet) based color scheme
## Window
`-Window` parameter launches the progress screen in a smaller window that can be dragged and resized. This is useful if you work on your implementation and need something in the background be accessible/visible while testing
## Icons
`-TemplateFile` parameter allow to edit the icons and phase messages of the progress screen, search for `IconPacks Browser` in the Microsoft Store. This app contains most of the available icons of the mahapps icon pack. Template Files are *psd1 files created using `New-OSDProgressTemplate`

# Unlock
Default password to unlock is simply `unlock`. OSDProgress looks for an osdprogress.pass file in system32 folder on startup. You can either add it manually or using the `Add-OSDProgressToWinPE` function. The unlock function is far from being a security limit, please do not use your domain admin password. This functionality will be expanded in the future to use a credential object. In this way, many options are available for retrieving this object (time-limited, randomly generated strings from a REST endpoint as an example)

# Additional Functions

## Read-OSDLog
Monitor a log file until search string matches on the last line and invoke a parameterized scriptblock

```powershell
    Read-OSDLog -LogFile "x:\file.log" -SearchString "Expand-WindowsImage" -Execution { Update-OSDProgress -Phase 3 }
```

## Import-OSDProgress
Used to import the current status of OSDProgress into background runspaces. Only required if you are working with multiple runspaces in your implementation.

## Get-OSDProgress
Returns hashtable of current status, mainly used for debugging

## Add-OSDProgressToWinPE
Function to modify boot images with OSDProgress and set custom passwords for unlock

This code snippet modify the OSDCloud boot image to start OSDProgress in "Server-Mode" before any command prompt, could result in a better end user experience :
```powershell
    Add-OSDProgressToWinPE -OSDCloud -WinpeshlIni -UnlockPass 'mysecret'
}
```
[Note: Function still under development, breaking changes could happen here]

## New-OSDProgressTemplate
Creates a new template file which can be used by `Invoke-OSDProgress` and `Start-OSDProgress` to adapt the 3 phase icons and status texts

# Important to know
OSDProgress use a dispatcher to update the UI in different runspaces, the dispatcher "pause" the UI while updating, so be carefull with your Update-OSDProgress usage.
Something like :

```powershell
    Invoke-OSDProgress -Window
    Update-OSDProgress -DisplayBar
    1..100 | Update-OSDProgress
    Stop-OSDProgress

}
```

It takes some time to finish, so it slows down your whole process if you call `Update-OSDProgress` in the same loop. So if you are copying many small files, it is not a good idea to run `Update-OSDProgress -Text" filenameX "` for each file. At the beginning of this project the `Save-OSDProgressFile` had the same behavior with faster internet connections, it doubled the download time. So I decided to split "Download Content" and "Update the ui" into different runspaces and to redesign `Update-OSDProgress`. As a result, the "Download" runspace can do its work without interruption and the "Update" runspace intercepts the current progress from time to time. Keep this in mind if you write your own function / script and call `Update-OSDProgress` frequently.

# Known issues
* The second time you launch a progress screen in the same Powershell process, the UI will freeze when you hit the unlock button (could be a bug with mahapps dialogs, should spend more time on research :relaxed: ). It's not a big problem. Why should you restart the progress screen if you have already unlocked it?!?!