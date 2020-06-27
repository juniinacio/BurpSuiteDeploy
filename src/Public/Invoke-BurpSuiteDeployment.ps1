function Invoke-BurpSuiteDeployment {
    [CmdletBinding(SupportsShouldProcess = $true,
        HelpUri = 'https://github.com/juniinacio/BurpSuiteDeploy',
        ConfirmImpact = 'Medium')]
    Param (
        [parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [psobject[]]$Deployments
    )

    begin {
        $siteTree = Get-BurpSuiteSiteTree
        $scanConfigurations = Get-BurpSuiteScanConfiguration
    }

    process {
        try {
            foreach ($deployment in $Deployments) {
                if ($PSCmdlet.ShouldProcess("Deploy", $deployment.ResourceId)) {
                    switch ($deployment.ResourceType) {
                        'BurpSuite/Sites' {
                            $resource = $siteTree.sites | Where-Object { $_.parent_id -eq 0 -and $_.name -eq $deployment.Name }
                            if ($null -eq $resource) {
                                $createSiteArgs = @{
                                    ParentId = "0"
                                    Name = $deployment.Name
                                    Scope = $deployment.Properties.scope
                                    ScanConfigurationIds = $deployment.Properties.scanConfigurationIds
                                }

                                if ($null -ne ($deployment.Properties.emailRecipients)) {
                                    $createSiteArgs.EmailRecipients = $deployment.Properties.emailRecipients
                                }

                                if ($null -ne ($deployment.Properties.applicationLogins)) {
                                    $createSiteArgs.ApplicationLogins = $deployment.Properties.applicationLogins
                                }

                                $resource = New-BurpSuiteSite @createSiteArgs
                            }
                        }

                        'BurpSuite/Folders' {
                            $resource = $siteTree.folders | Where-Object { $_.parent_id -eq 0 -and $_.name -eq $deployment.Name }
                            if ($null -eq $resource) {
                                $resource = New-BurpSuiteFolder -ParentId 0 -Name $deployment.Name
                            }
                        }

                        'BurpSuite/Folders/Sites' {
                            $parentResourceId = ($deployment.ResourceId -split '/' | Select-Object -First 3) -join '/'
                            $parentResource = [deploymentCache]::Get($parentResourceId)

                            if ($null -ne $parentResource) {
                                $resource = $siteTree.sites | Where-Object { $_.parent_id -eq 0 -and $_.name -eq $deployment.Name }
                                if ($null -eq $resource) {
                                    $createSiteArgs = @{
                                        ParentId = $parentResource.Id
                                        Name = $deployment.Name
                                        Scope = $deployment.Properties.scope
                                        ScanConfigurationIds = $deployment.Properties.scanConfigurationIds
                                    }

                                    if ($null -ne ($deployment.Properties.emailRecipients)) {
                                        $createSiteArgs.EmailRecipients = $deployment.Properties.emailRecipients
                                    }

                                    if ($null -ne ($deployment.Properties.applicationLogins)) {
                                        $createSiteArgs.ApplicationLogins = $deployment.Properties.applicationLogins
                                    }

                                    $resource = New-BurpSuiteSite @createSiteArgs
                                }
                            } else {
                                throw "Resource $($deployment.ResourceId) parent could not be determined."
                            }
                        }

                        'BurpSuite/ScanConfigurations' {
                            $resource = $scanConfigurations | Where-Object { $_.name -eq $deployment.Name }
                            if ($null -eq $resource) {
                                $tempFile = _createTempFile -InputObject $deployment.Properties.scanConfigurationFragmentJson
                                $resource = New-BurpSuiteScanConfiguration -Name $deployment.Name -FilePath $tempFile.FullName
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

                    [deploymentCache]::deployments += $deploymentResult

                    $deploymentResult
                }
            }
        } catch {
            throw
        }
    }

    end {
    }
}
