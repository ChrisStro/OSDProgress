function Test-UI {
    if ($Script:ProgressUI.Form.IsVisible) {
        $true
    }
    else {
        $false
    }
}