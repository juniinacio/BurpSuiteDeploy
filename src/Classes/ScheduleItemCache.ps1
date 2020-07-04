class ScheduleItemCache {
    static [object[]] $ScheduleItems

    static [object] Get([string]$siteId) {
        return @([ScheduleItemCache]::ScheduleItems | Where-Object { $_.site.id -eq $siteId })
    }
}
