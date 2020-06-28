function Invoke-BurpSuiteDeployment {
    [CmdletBinding(SupportsShouldProcess = $true,
        HelpUri = 'https://github.com/juniinacio/BurpSuiteDeploy',
        ConfirmImpact = 'Medium')]
    Param (
        [parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [psobject]$Deployment
    )

    begin {
        [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
        [ScanConfigurationCache]::ScanConfigurations = @(Get-BurpSuiteScanConfiguration)
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Deploy", $deployment.ResourceId)) {
                switch ($deployment.ResourceType) {
                    'BurpSuite/Sites' {
                        $resource = [SiteTreeCache]::Get(0, $deployment.Name, 'Sites')
                        if ($null -eq $resource) {
                            $parameters = @{
                                ParentId             = "0"
                                Name                 = $deployment.Name
                                Scope                = $deployment.Properties.scope
                                ScanConfigurationIds = $deployment.Properties.scanConfigurationIds
                            }

                            if ($null -ne ($deployment.Properties.emailRecipients)) {
                                $parameters.EmailRecipients = $deployment.Properties.emailRecipients
                            }

                            if ($null -ne ($deployment.Properties.applicationLogins)) {
                                $applicationLogins = @()

                                foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                    $applicationLogins += [PSCustomObject]@{ Label = $applicationLogin.Label; Username = $applicationLogin.Username; Password = $applicationLogin.Password }
                                }

                                $parameters.ApplicationLogins = $applicationLogins
                            }

                            $resource = New-BurpSuiteSite @parameters

                            [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                        }
                    }

                    'BurpSuite/Folders' {
                        $resource = [SiteTreeCache]::Get(0, $deployment.Name, 'Folders')
                        if ($null -eq $resource) {
                            $resource = New-BurpSuiteFolder -ParentId 0 -Name $deployment.Name

                            [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                        }
                    }

                    'BurpSuite/Folders/Sites' {
                        $parentResourceId = ($deployment.ResourceId -split '/' | Select-Object -First 3) -join '/'
                        $parentResource = [DeploymentCache]::Get($parentResourceId)

                        if ($null -ne $parentResource) {
                            $resource = [SiteTreeCache]::Get($parentResource.Id, $deployment.Name, 'Sites')
                            if ($null -eq $resource) {
                                $parameters = @{
                                    ParentId             = $parentResource.Id
                                    Name                 = $deployment.Name
                                    Scope                = $deployment.Properties.scope
                                    ScanConfigurationIds = $deployment.Properties.scanConfigurationIds
                                }

                                if ($null -ne ($deployment.Properties.emailRecipients)) {
                                    $parameters.EmailRecipients = $deployment.Properties.emailRecipients
                                }

                                if ($null -ne ($deployment.Properties.applicationLogins)) {
                                    $applicationLogins = @()

                                    foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                        $applicationLogins += [PSCustomObject]@{ Label = $applicationLogin.Label; Username = $applicationLogin.Username; Password = $applicationLogin.Password }
                                    }

                                    $parameters.ApplicationLogins = $applicationLogins
                                }

                                $resource = New-BurpSuiteSite @parameters

                                [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                            } else {
                                if ($null -ne ($deployment.Properties.applicationLogins)) {
                                    foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                        $appPass = ConvertTo-SecureString -String $applicationLogin.password -AsPlainText -Force
                                        $appCredential =  New-Object -TypeName PSCredential -ArgumentList $applicationLogin.username, $appPass
                                        $appLogin = $resource.application_logins | Where-Object { $_.label -eq $applicationLogin.label }
                                        if ($null -eq $appLogin) {
                                            New-BurpSuiteSiteApplicationLogin -SiteId $resource.id -Label $applicationLogin.label -Credential $appCredential
                                        } else {
                                            Update-BurpSuiteSiteApplicationLogin -Id $appLogin.id -Label $applicationLogin.label -Credential $appCredential
                                        }
                                    }
                                }
                            }
                        } else {
                            throw "Resource $($deployment.ResourceId) parent could not be determined."
                        }
                    }

                    'BurpSuite/ScanConfigurations' {
                        $tempFile = _createTempFile -InputObject $deployment.Properties.scanConfigurationFragmentJson

                        $resource = [ScanConfigurationCache]::Get($deployment.Name)
                        if ($null -eq $resource) {
                            $resource = New-BurpSuiteScanConfiguration -Name $deployment.Name -FilePath $tempFile.FullName

                            [ScanConfigurationCache]::ScanConfigurations = @(Get-BurpSuiteScanConfiguration)
                        } else {
                            Update-BurpSuiteScanConfiguration -Id $resource.Id -FilePath $tempFile.FullName
                        }
                    }

                    default {
                        throw "Unknown resource type."
                    }
                }

                $deploymentResult = [PSCustomObject]@{
                    Id                = $resource.Id
                    ResourceId        = $deployment.ResourceId
                    ProvisioningState = [ProvisioningState]::Succeeded
                }

                [DeploymentCache]::deployments += $deploymentResult

                $deploymentResult
            }
        } catch {
            throw
        }
    }

    end {
    }
}
