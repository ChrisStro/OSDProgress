function Stop-PipeCommunication ([hashtable]$PipeHash) {
    foreach ($key in $PipeHash.Keys) {
        $PipeHash.$key.Dispose()
    }
}