class ScheduleItemCache {
    static [object[]] $ScheduleItems

    static [object] Get([string]$siteId) {
        return @([ScheduleItemCache]::ScheduleItems | Where-Object { $_.site.id -eq $siteId })
    }

    static [void] Reload() {
        [ScheduleItemCache]::Init()
    }

    static [void] Init() {
        [ScheduleItemCache]::ScheduleItems = @(Get-BurpSuiteScheduleItem -Fields id, schedule, site)
    }
}
