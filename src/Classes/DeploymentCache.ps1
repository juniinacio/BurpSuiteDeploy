class DeploymentCache {
    static [object[]] $Deployments = @()
    static [object] Get([string]$resourceId) {
        return @([DeploymentCache]::Deployments | Where-Object {$_.ResourceId -eq $resourceId})[0]
    }
}
