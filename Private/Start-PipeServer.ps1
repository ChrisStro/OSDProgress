function Start-PipeServer {
    $ht = [ordered]@{}
    $ht.server = new-object System.IO.Pipes.NamedPipeServerStream "OSDPipe", "In"
    $ht.sr = new-object System.IO.StreamReader $ht.server

    return $ht
}