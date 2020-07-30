class DeploymentCache {
    static [object[]] $Deployments = @()

    static [object] Get([string]$resourceId) {
        return @([DeploymentCache]::Deployments | Where-Object {$_.ResourceId -eq $resourceId})[0]
    }

    static [object] Get() {
        return [DeploymentCache]::Deployments
    }

    static [void] Set([object]$deployment) {
        [DeploymentCache]::Deployments += $deployment
    }

    static [void] Init() {
        [DeploymentCache]::Deployments = @()
    }
}
