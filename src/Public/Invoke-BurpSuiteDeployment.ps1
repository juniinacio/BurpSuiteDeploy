function Invoke-BurpSuiteDeployment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
            Write-Verbose "Deploying resource $($deployment.ResourceId)`..."

            if ($PSCmdlet.ShouldProcess("Deploy", $deployment.ResourceId)) {
                switch ($deployment.ResourceType) {
                    'BurpSuite/Sites' {
                        $resource = [SiteTreeCache]::Get(0, $deployment.Name, 'Sites')
                        if ($null -eq $resource) {

                            $scanConfigurationIds = @()
                            foreach ($scanConfigurationId in $deployment.Properties.scanConfigurationIds) {
                                if ((_testIsExpression -InputString $scanConfigurationId)) {
                                    $resolvedScanConfigurationId = _resolveExpression -inputString $scanConfigurationId -variables @{} -resources ([DeploymentCache]::Deployments)
                                    if ($null -eq $resolvedScanConfigurationId) {
                                        throw "Could not resolve dependency expression $scanConfigurationId`."
                                    }
                                    $scanConfigurationIds += $resolvedScanConfigurationId
                                } else {
                                    $scanConfigurationIds += $scanConfigurationId
                                }
                            }

                            $parameters = @{
                                ParentId             = "0"
                                Name                 = $deployment.Name
                                Scope                = $deployment.Properties.scope
                                ScanConfigurationIds = $scanConfigurationIds
                            }

                            if ($null -ne ($deployment.Properties.emailRecipients)) {
                                $parameters.EmailRecipients = $deployment.Properties.emailRecipients
                            }

                            if ($null -ne ($deployment.Properties.applicationLogins)) {
                                $applicationLogins = @()

                                foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                    $applicationLogins += [PSCustomObject]@{ Label = $applicationLogin.Label; Credential = (New-Object System.Management.Automation.PSCredential ($applicationLogin.Username, $(ConvertTo-SecureString $applicationLogin.Password -AsPlainText -Force))) }
                                }

                                $parameters.ApplicationLogins = $applicationLogins
                            }

                            $resource = New-BurpSuiteSite @parameters

                            [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                        } else {

                            if ($null -ne ($deployment.Properties.scope)) {
                                Update-BurpSuiteSiteScope -SiteId $resource.Id -IncludedUrls $deployment.Properties.scope.includedUrls -ExcludedUrls $deployment.Properties.scope.excludedUrls
                            }

                            if ($null -ne ($deployment.Properties.scanConfigurationIds)) {
                                $scanConfigurationIds = @()
                                foreach ($scanConfigurationId in $deployment.Properties.scanConfigurationIds) {
                                    if ((_testIsExpression -InputString $scanConfigurationId)) {
                                        $resolvedScanConfigurationId = _resolveExpression -inputString $scanConfigurationId -variables @{} -resources ([DeploymentCache]::Deployments)
                                        if ($null -eq $resolvedScanConfigurationId) {
                                            throw "Could not resolve dependency expression $scanConfigurationId`."
                                        }
                                        $scanConfigurationIds += $resolvedScanConfigurationId
                                    } else {
                                        $scanConfigurationIds += $scanConfigurationId
                                    }
                                }
                                Update-BurpSuiteSiteScanConfiguration -Id $resource.Id -ScanConfigurationIds $scanConfigurationIds
                            }

                            if ($null -ne ($deployment.Properties.applicationLogins)) {
                                foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                    $appPass = ConvertTo-SecureString -String $applicationLogin.password -AsPlainText -Force
                                    $appCredential = New-Object -TypeName PSCredential -ArgumentList $applicationLogin.username, $appPass
                                    $appLogin = $resource.application_logins | Where-Object { $_.label -eq $applicationLogin.label }
                                    if ($null -eq $appLogin) {
                                        New-BurpSuiteSiteApplicationLogin -SiteId $resource.id -Label $applicationLogin.label -Credential $appCredential | Out-Null
                                    } else {
                                        Update-BurpSuiteSiteApplicationLogin -Id $appLogin.id -Credential $appCredential
                                    }
                                }
                            }

                            if ($null -ne ($deployment.Properties.emailRecipients)) {
                                foreach ($emailRecipient in $deployment.Properties.emailRecipients) {
                                    $emailRec = $resource.email_recipients | Where-Object { $_.email -eq $emailRecipient.email }
                                    if ($null -eq $emailRec) {
                                        New-BurpSuiteSiteEmailRecipient -SiteId $resource.id -EmailRecipient $emailRecipient.email | Out-Null
                                    } else {
                                        Update-BurpSuiteSiteEmailRecipient -Id $emailRec.id -Email $emailRecipient.email
                                    }
                                }
                            }
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

                                $scanConfigurationIds = @()
                                foreach ($scanConfigurationId in $deployment.Properties.scanConfigurationIds) {
                                    if ((_testIsExpression -InputString $scanConfigurationId)) {
                                        $resolvedScanConfigurationId = _resolveExpression -inputString $scanConfigurationId -variables @{} -resources ([DeploymentCache]::Deployments)
                                        if ($null -eq $resolvedScanConfigurationId) {
                                            throw "Could not resolve dependency expression $scanConfigurationId`."
                                        }
                                        $scanConfigurationIds += $resolvedScanConfigurationId
                                    } else {
                                        $scanConfigurationIds += $scanConfigurationId
                                    }
                                }

                                $parameters = @{
                                    ParentId             = $parentResource.Id
                                    Name                 = $deployment.Name
                                    Scope                = $deployment.Properties.scope
                                    ScanConfigurationIds = $scanConfigurationIds
                                }

                                if ($null -ne ($deployment.Properties.emailRecipients)) {
                                    $parameters.EmailRecipients = $deployment.Properties.emailRecipients
                                }

                                if ($null -ne ($deployment.Properties.applicationLogins)) {
                                    $applicationLogins = @()

                                    foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                        $applicationLogins += [PSCustomObject]@{ Label = $applicationLogin.Label; Credential = (New-Object System.Management.Automation.PSCredential ($applicationLogin.Username, $(ConvertTo-SecureString $applicationLogin.Password -AsPlainText -Force))) }
                                    }

                                    $parameters.ApplicationLogins = $applicationLogins
                                }

                                $resource = New-BurpSuiteSite @parameters

                                [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                            } else {

                                if ($null -ne ($deployment.Properties.scope)) {
                                    Update-BurpSuiteSiteScope -SiteId $resource.Id -IncludedUrls $deployment.Properties.scope.includedUrls -ExcludedUrls $deployment.Properties.scope.excludedUrls
                                }

                                if ($null -ne ($deployment.Properties.scanConfigurationIds)) {
                                    $scanConfigurationIds = @()
                                    foreach ($scanConfigurationId in $deployment.Properties.scanConfigurationIds) {
                                        if ((_testIsExpression -InputString $scanConfigurationId)) {
                                            $resolvedScanConfigurationId = _resolveExpression -inputString $scanConfigurationId -variables @{} -resources ([DeploymentCache]::Deployments)
                                            if ($null -eq $resolvedScanConfigurationId) {
                                                throw "Could not resolve dependency expression $scanConfigurationId`."
                                            }
                                            $scanConfigurationIds += $resolvedScanConfigurationId
                                        } else {
                                            $scanConfigurationIds += $scanConfigurationId
                                        }
                                    }
                                    Update-BurpSuiteSiteScanConfiguration -Id $resource.Id -ScanConfigurationIds $scanConfigurationIds
                                }

                                if ($null -ne ($deployment.Properties.applicationLogins)) {
                                    foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                        $appPass = ConvertTo-SecureString -String $applicationLogin.password -AsPlainText -Force
                                        $appCredential = New-Object -TypeName PSCredential -ArgumentList $applicationLogin.username, $appPass
                                        $appLogin = $resource.application_logins | Where-Object { $_.label -eq $applicationLogin.label }
                                        if ($null -eq $appLogin) {
                                            New-BurpSuiteSiteApplicationLogin -SiteId $resource.id -Label $applicationLogin.label -Credential $appCredential | Out-Null
                                        } else {
                                            Update-BurpSuiteSiteApplicationLogin -Id $appLogin.id -Credential $appCredential
                                        }
                                    }
                                }

                                if ($null -ne ($deployment.Properties.emailRecipients)) {
                                    foreach ($emailRecipient in $deployment.Properties.emailRecipients) {
                                        $emailRec = $resource.email_recipients | Where-Object { $_.email -eq $emailRecipient.email }
                                        if ($null -eq $emailRec) {
                                            New-BurpSuiteSiteEmailRecipient -SiteId $resource.id -EmailRecipient $emailRecipient.email | Out-Null
                                        } else {
                                            Update-BurpSuiteSiteEmailRecipient -Id $emailRec.id -Email $emailRecipient.email
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

                $provResultProperties = @{
                    Id                = $resource.Id
                    ResourceId        = $deployment.ResourceId
                    ProvisioningState = [ProvisioningState]::Succeeded
                    Properties        = $resource
                }
            }
        } catch {
            $provResultProperties = @{
                Id                = $resource.Id
                ResourceId        = $deployment.ResourceId
                ProvisioningState = [ProvisioningState]::Error
                ProvisioningError = $_.Exception.Message.ToString()
                Properties        = $resource
            }
        }

        $provisioningResult = [PSCustomObject]$provResultProperties
        [DeploymentCache]::Deployments += $provisioningResult
        $provisioningResult
    }

    end {
    }
}
