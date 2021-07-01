function Test-PipeServer {
    $pipe = Get-ChildItem \\.\pipe\ -Filter OSDPipe
    if ($pipe) {
        $true
    }
    else {
        $false
    }
}