function ConvertToHashtable {
    param([object]$InputObject)

    $ht = @{}

    $InputObject | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $ht.$_ = $InputObject.$_
    }

    $ht
}
