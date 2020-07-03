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

                            Write-Verbose "Creating site $($deployment.Name)`..."

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

                            Write-Verbose "Updating site $($deployment.Name)`..."

                            if ($null -ne ($deployment.Properties.scope)) {
                                Write-Verbose " Updating site scopes..."
                                Update-BurpSuiteSiteScope -SiteId $resource.Id -IncludedUrls $deployment.Properties.scope.includedUrls -ExcludedUrls $deployment.Properties.scope.excludedUrls
                                Start-Sleep -Seconds 1
                            }

                            if ($null -ne ($deployment.Properties.scanConfigurationIds)) {
                                Write-Verbose " Updating scan configuration..."
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
                                Start-Sleep -Seconds 1
                            }

                            [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                            $resource = [SiteTreeCache]::Get(0, $deployment.Name, 'Sites')

                            if ($null -ne ($deployment.Properties.applicationLogins)) {
                                Write-Verbose " Updating application logins..."
                                foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                    $appPass = ConvertTo-SecureString -String $applicationLogin.password -AsPlainText -Force
                                    $appCredential = New-Object -TypeName PSCredential -ArgumentList $applicationLogin.username, $appPass
                                    $appLogin = $resource.application_logins | Where-Object { $_.label -eq $applicationLogin.label }
                                    if ($null -eq $appLogin) {
                                        New-BurpSuiteSiteApplicationLogin -SiteId $resource.id -Label $applicationLogin.label -Credential $appCredential | Out-Null
                                    } else {
                                        Update-BurpSuiteSiteApplicationLogin -Id $appLogin.id -Credential $appCredential
                                    }
                                    Start-Sleep -Seconds 1
                                }
                            }

                            if ($null -ne ($deployment.Properties.emailRecipients)) {
                                Write-Verbose " Updating email recipients..."
                                foreach ($emailRecipient in $deployment.Properties.emailRecipients) {
                                    $emailRec = $resource.email_recipients | Where-Object { $_.email -eq $emailRecipient.email }
                                    if ($null -eq $emailRec) {
                                        New-BurpSuiteSiteEmailRecipient -SiteId $resource.id -EmailRecipient $emailRecipient.email | Out-Null
                                    } else {
                                        Update-BurpSuiteSiteEmailRecipient -Id $emailRec.id -Email $emailRecipient.email
                                    }
                                    Start-Sleep -Seconds 1
                                }
                            }
                        }
                    }

                    'BurpSuite/Folders' {
                        $resource = [SiteTreeCache]::Get(0, $deployment.Name, 'Folders')
                        if ($null -eq $resource) {
                            Write-Verbose "Creating folder $($deployment.Name)`..."
                            $resource = New-BurpSuiteFolder -ParentId 0 -Name $deployment.Name
                            [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                            Start-Sleep -Seconds 1
                        }
                    }

                    'BurpSuite/Folders/Sites' {
                        $parentResourceId = ($deployment.ResourceId -split '/' | Select-Object -First 3) -join '/'
                        $parentResource = [DeploymentCache]::Get($parentResourceId)

                        if ($null -ne $parentResource) {
                            $resource = [SiteTreeCache]::Get($parentResource.Id, $deployment.Name, 'Sites')
                            if ($null -eq $resource) {
                                Write-Verbose "Creating site $($deployment.Name), parent id $($parentResource.Id)`..."

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
                                Write-Verbose "Updating site $($deployment.Name), parent id $($parentResource.Id)`..."

                                if ($null -ne ($deployment.Properties.scope)) {
                                    Write-Verbose " Updating site scopes..."
                                    Update-BurpSuiteSiteScope -SiteId $resource.Id -IncludedUrls $deployment.Properties.scope.includedUrls -ExcludedUrls $deployment.Properties.scope.excludedUrls
                                    Start-Sleep -Seconds 1
                                }

                                if ($null -ne ($deployment.Properties.scanConfigurationIds)) {
                                    Write-Verbose " Updating scan configurations..."
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
                                    Start-Sleep -Seconds 1
                                }

                                [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                                $resource = [SiteTreeCache]::Get($parentResource.Id, $deployment.Name, 'Sites')

                                if ($null -ne ($deployment.Properties.applicationLogins)) {
                                    Write-Verbose " Updating application logins..."
                                    foreach ($applicationLogin in $deployment.Properties.applicationLogins) {
                                        $appPass = ConvertTo-SecureString -String $applicationLogin.password -AsPlainText -Force
                                        $appCredential = New-Object -TypeName PSCredential -ArgumentList $applicationLogin.username, $appPass
                                        $appLogin = $resource.application_logins | Where-Object { $_.label -eq $applicationLogin.label }
                                        if ($null -eq $appLogin) {
                                            New-BurpSuiteSiteApplicationLogin -SiteId $resource.id -Label $applicationLogin.label -Credential $appCredential | Out-Null
                                        } else {
                                            Update-BurpSuiteSiteApplicationLogin -Id $appLogin.id -Credential $appCredential
                                        }
                                        Start-Sleep -Seconds 1
                                    }
                                }

                                if ($null -ne ($deployment.Properties.emailRecipients)) {
                                    Write-Verbose " Updating email recipients..."
                                    foreach ($emailRecipient in $deployment.Properties.emailRecipients) {
                                        $emailRec = $resource.email_recipients | Where-Object { $_.email -eq $emailRecipient.email }
                                        if ($null -eq $emailRec) {
                                            New-BurpSuiteSiteEmailRecipient -SiteId $resource.id -EmailRecipient $emailRecipient.email | Out-Null
                                        } else {
                                            Update-BurpSuiteSiteEmailRecipient -Id $emailRec.id -Email $emailRecipient.email
                                        }
                                        Start-Sleep -Seconds 1
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
                            Write-Verbose "Creating scan configuration $($deployment.Name)`..."
                            $resource = New-BurpSuiteScanConfiguration -Name $deployment.Name -FilePath $tempFile.FullName
                            [ScanConfigurationCache]::ScanConfigurations = @(Get-BurpSuiteScanConfiguration)
                        } else {
                            Write-Verbose "Updating scan configuration $($deployment.Name)`..."
                            Update-BurpSuiteScanConfiguration -Id $resource.Id -FilePath $tempFile.FullName
                        }
                        Start-Sleep -Seconds 1
                    }

                    default {
                        throw "Unknown resource type."
                    }
                }

                $provisioningResult = [PSCustomObject]@{
                    Id                = $resource.Id
                    ResourceId        = $deployment.ResourceId
                    ProvisioningState = [ProvisioningState]::Succeeded
                    Properties        = $resource
                }
            }
        } catch {
            $provisioningResult = [PSCustomObject]@{
                Id                = $resource.Id
                ResourceId        = $deployment.ResourceId
                ProvisioningState = [ProvisioningState]::Error
                ProvisioningError = $_.Exception.Message.ToString()
                Properties        = $resource
            }
        }

        [DeploymentCache]::Deployments += $provisioningResult
        $provisioningResult
    }

    end {
    }
}
