function CreateTempFile {
    param([object]$InputObject)

    $tempFile = New-TemporaryFile
    if (-not ([string]::IsNullOrEmpty($InputObject))) {
        Out-File -NoNewline -InputObject $InputObject -FilePath $tempFile
    }
    $tempFile
}
