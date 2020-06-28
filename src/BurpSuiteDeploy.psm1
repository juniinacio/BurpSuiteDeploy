[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

# $ExecutionContext.SessionState.Module.OnRemove = {
#     [DeploymentCache]::Deployments = @()
#     [ScanConfigurationCache]::ScanConfigurations = @()
#     [SiteTreeCache]::SiteTree = $null
# }
