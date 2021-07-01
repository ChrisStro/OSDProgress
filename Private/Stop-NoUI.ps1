function Stop-NoUI {
    if (-not ((Test-UI) -or (Test-PipeServer))) {
        Write-Warning "No UI/UI-Server running"
        break
    }
}