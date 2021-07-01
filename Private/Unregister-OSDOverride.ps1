function Unregister-OSDOverride {
    $isSet = test-path Alias:\Save-WebFile
    if ($isSet) {
        Write-Verbose "Remove Alias with Name 'Save-WebFile' for 'Save-WebFileOverride'"
        Remove-Item Alias:Save-WebFile
    }
}