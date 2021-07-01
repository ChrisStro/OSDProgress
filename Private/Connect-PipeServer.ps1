function Connect-PipeServer {
    $ht = [ordered]@{}
    $ht.client = new-object System.IO.Pipes.NamedPipeClientStream ".", "OSDPipe", "Out"
    $ht.client.Connect()
    $ht.sw = new-object System.IO.StreamWriter $ht.client
    $ht.sw.AutoFlush = $true

    return $ht
}