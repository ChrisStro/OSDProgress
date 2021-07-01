function Stop-ProgressDone {
    if ($ProgressUI.Phase -eq "PhaseFinish") {
        Write-Warning "Progress is already finished, there's no reason to update"
        break
    }
}