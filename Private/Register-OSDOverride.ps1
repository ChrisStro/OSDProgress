function Register-OSDOverride {
    $isSet = test-path Alias:\Save-WebFile
    if (!$isSet) {
        $installed = Test-OSDModule
        if ($installed) {
            Write-Verbose "Create Alias with Name 'Save-WebFile' for 'Save-WebFileOverride'"
            New-Alias -Name Save-WebFile -Value Save-WebFileOverride -Scope Global
        }
        else {
            Write-Warning "No 'OSD' Module present, run 'install-module OSD' first"
        }
    }
}