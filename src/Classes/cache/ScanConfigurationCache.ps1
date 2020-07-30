class ScanConfigurationCache {
    static [object[]] $ScanConfigurations = @()

    static [object] Get([string]$name) {
        return @([ScanConfigurationCache]::ScanConfigurations | Where-Object { $_.name -eq $name })[0]
    }

    static [void] Reload() {
        [ScanConfigurationCache]::Init()
    }

    static [void] Init() {
        [ScanConfigurationCache]::ScanConfigurations = @(Get-BurpSuiteScanConfiguration)
    }
}
