function New-BurpSuiteResource {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding(SupportsShouldProcess = $true,
        HelpUri = 'https://github.com/juniinacio/BurpSuiteDeploy',
        ConfirmImpact = 'Medium')]
    Param (
        [parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [psobject]$InputObject
    )

    begin {
        [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
        [ScanConfigurationCache]::ScanConfigurations = @(Get-BurpSuiteScanConfiguration)
        [ScheduleItemCache]::ScheduleItems = @(Get-BurpSuiteScheduleItem -Fields id, schedule, site)
    }

    process {
        try {
            Write-Verbose "Deploying resource $($InputObject.ResourceId)`..."

            if ($PSCmdlet.ShouldProcess("Deploy", $InputObject.ResourceId)) {
                switch ($InputObject.ResourceType) {
                    'BurpSuite/Sites' {
                        $resource = [SiteTreeCache]::Get(0, $InputObject.Name, 'Sites')
                        if ($null -eq $resource) {

                            Write-Verbose "Creating site $($InputObject.Name)`..."

                            $scanConfigurationIds = @()
                            foreach ($scanConfigurationId in $InputObject.Properties.scanConfigurationIds) {
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
                                Name                 = $InputObject.Name
                                Scope                = $InputObject.Properties.scope
                                ScanConfigurationIds = $scanConfigurationIds
                            }

                            if ($null -ne ($InputObject.Properties.emailRecipients)) {
                                $parameters.EmailRecipients = $InputObject.Properties.emailRecipients
                            }

                            if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                $applicationLogins = @()

                                foreach ($applicationLogin in $InputObject.Properties.applicationLogins) {
                                    $applicationLogins += [PSCustomObject]@{ Label = $applicationLogin.Label; Credential = (New-Object System.Management.Automation.PSCredential ($applicationLogin.Username, $(ConvertTo-SecureString $applicationLogin.Password -AsPlainText -Force))) }
                                }

                                $parameters.ApplicationLogins = $applicationLogins
                            }

                            $resource = New-BurpSuiteSite @parameters

                            [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                        } else {

                            Write-Verbose "Updating site $($InputObject.Name)`..."

                            if ($null -ne ($InputObject.Properties.scope)) {
                                Write-Verbose " Updating site scopes..."
                                Update-BurpSuiteSiteScope -SiteId $resource.Id -IncludedUrls $InputObject.Properties.scope.includedUrls -ExcludedUrls $InputObject.Properties.scope.excludedUrls
                                Start-Sleep -Seconds 1
                            }

                            if ($null -ne ($InputObject.Properties.scanConfigurationIds)) {
                                Write-Verbose " Updating scan configuration..."
                                $scanConfigurationIds = @()
                                foreach ($scanConfigurationId in $InputObject.Properties.scanConfigurationIds) {
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
                            $resource = [SiteTreeCache]::Get(0, $InputObject.Name, 'Sites')

                            if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                Write-Verbose " Updating application logins..."
                                foreach ($applicationLogin in $InputObject.Properties.applicationLogins) {
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

                            if ($null -ne ($InputObject.Properties.emailRecipients)) {
                                Write-Verbose " Updating email recipients..."
                                foreach ($emailRecipient in $InputObject.Properties.emailRecipients) {
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
                        $resource = [SiteTreeCache]::Get(0, $InputObject.Name, 'Folders')
                        if ($null -eq $resource) {
                            Write-Verbose "Creating folder $($InputObject.Name)`..."
                            $resource = New-BurpSuiteFolder -ParentId 0 -Name $InputObject.Name
                            [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                            Start-Sleep -Seconds 1
                        }
                    }

                    'BurpSuite/Folders/Sites' {
                        $parentResourceId = ($InputObject.ResourceId -split '/' | Select-Object -First 3) -join '/'
                        $parentResource = [DeploymentCache]::Get($parentResourceId)

                        if ($null -ne $parentResource) {
                            $resource = [SiteTreeCache]::Get($parentResource.Id, $InputObject.Name, 'Sites')
                            if ($null -eq $resource) {
                                Write-Verbose "Creating site $($InputObject.Name), parent id $($parentResource.Id)`..."

                                $scanConfigurationIds = @()
                                foreach ($scanConfigurationId in $InputObject.Properties.scanConfigurationIds) {
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
                                    Name                 = $InputObject.Name
                                    Scope                = $InputObject.Properties.scope
                                    ScanConfigurationIds = $scanConfigurationIds
                                }

                                if ($null -ne ($InputObject.Properties.emailRecipients)) {
                                    $parameters.EmailRecipients = $InputObject.Properties.emailRecipients
                                }

                                if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                    $applicationLogins = @()

                                    foreach ($applicationLogin in $InputObject.Properties.applicationLogins) {
                                        $applicationLogins += [PSCustomObject]@{ Label = $applicationLogin.Label; Credential = (New-Object System.Management.Automation.PSCredential ($applicationLogin.Username, $(ConvertTo-SecureString $applicationLogin.Password -AsPlainText -Force))) }
                                    }

                                    $parameters.ApplicationLogins = $applicationLogins
                                }

                                $resource = New-BurpSuiteSite @parameters

                                [SiteTreeCache]::SiteTree = Get-BurpSuiteSiteTree
                            } else {
                                Write-Verbose "Updating site $($InputObject.Name), parent id $($parentResource.Id)`..."

                                if ($null -ne ($InputObject.Properties.scope)) {
                                    Write-Verbose " Updating site scopes..."
                                    Update-BurpSuiteSiteScope -SiteId $resource.Id -IncludedUrls $InputObject.Properties.scope.includedUrls -ExcludedUrls $InputObject.Properties.scope.excludedUrls
                                    Start-Sleep -Seconds 1
                                }

                                if ($null -ne ($InputObject.Properties.scanConfigurationIds)) {
                                    Write-Verbose " Updating scan configurations..."
                                    $scanConfigurationIds = @()
                                    foreach ($scanConfigurationId in $InputObject.Properties.scanConfigurationIds) {
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
                                $resource = [SiteTreeCache]::Get($parentResource.Id, $InputObject.Name, 'Sites')

                                if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                    Write-Verbose " Updating application logins..."
                                    foreach ($applicationLogin in $InputObject.Properties.applicationLogins) {
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

                                if ($null -ne ($InputObject.Properties.emailRecipients)) {
                                    Write-Verbose " Updating email recipients..."
                                    foreach ($emailRecipient in $InputObject.Properties.emailRecipients) {
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
                            throw "Resource $($InputObject.ResourceId) parent could not be determined."
                        }
                    }

                    'BurpSuite/ScanConfigurations' {
                        $tempFile = _createTempFile -InputObject $InputObject.Properties.scanConfigurationFragmentJson

                        $resource = [ScanConfigurationCache]::Get($InputObject.Name)
                        if ($null -eq $resource) {
                            Write-Verbose "Creating scan configuration $($InputObject.Name)`..."
                            $resource = New-BurpSuiteScanConfiguration -Name $InputObject.Name -FilePath $tempFile.FullName
                            [ScanConfigurationCache]::ScanConfigurations = @(Get-BurpSuiteScanConfiguration)
                        } else {
                            Write-Verbose "Updating scan configuration $($InputObject.Name)`..."
                            Update-BurpSuiteScanConfiguration -Id $resource.Id -FilePath $tempFile.FullName
                        }
                        Start-Sleep -Seconds 1
                    }

                    'BurpSuite/ScheduleItems' {
                        $siteId = $InputObject.Properties.siteId
                        if ((_testIsExpression -InputString $siteId)) {
                            $resolvedSiteId = _resolveExpression -inputString $siteId -variables @{} -resources ([DeploymentCache]::Deployments)
                            if ($null -eq $resolvedSiteId) {
                                throw "Could not resolve expression $siteId`."
                            }
                            $siteId = $resolvedSiteId
                        }

                        $site = [SiteTreeCache]::Get($siteId, 'Sites')
                        if ($null -eq $site) {
                            throw "Could not find site with resource id $siteId`."
                        }

                        $scanConfigurationIds = _tryGetProperty -InputObject $InputObject.Properties -PropertyName 'scanConfigurationIds'
                        if ($null -eq $scanConfigurationIds) {
                            $scanConfigurationIds = $site.scan_configurations.id
                        }

                        $resolvedScanConfigurationIds = @()
                        foreach ($scanConfigurationId in $scanConfigurationIds) {
                            if ((_testIsExpression -InputString $scanConfigurationId)) {
                                $resolvedScanConfigurationId = _resolveExpression -inputString $scanConfigurationId -variables @{} -resources ([DeploymentCache]::Deployments)
                                if ($null -eq $resolvedScanConfigurationId) {
                                    throw "Could not resolve expression $scanConfigurationId`."
                                }
                                $resolvedScanConfigurationIds += $resolvedScanConfigurationId
                            } else {
                                $resolvedScanConfigurationIds += $scanConfigurationId
                            }
                        }

                        $recurrenceRule = _tryGetProperty -InputObject $InputObject.Properties.schedule -PropertyName 'rRule'
                        if (-not ([string]::IsNullOrEmpty($recurrenceRule))) {
                            $resource = [ScheduleItemCache]::Get($siteId) | Where-Object { $_.schedule.rrule -eq $recurrenceRule } | Select-Object -First 1
                        } else {
                            $resource = $null
                        }

                        if ($null -eq $resource) {
                            Write-Verbose "Creating schedule item $($InputObject.Name), site $siteId`..."

                            $parameters = @{}

                            $recurrenceRule = _tryGetProperty -InputObject $InputObject.Properties.schedule -PropertyName 'rRule'
                            if (-not ([string]::IsNullOrEmpty($recurrenceRule))) {
                                $parameters.rrule = $recurrenceRule
                            }

                            $initialRunTime = _tryGetProperty -InputObject $InputObject.Properties.schedule -PropertyName 'initialRunTime'
                            if (-not ([string]::IsNullOrEmpty($initialRunTime))) {
                                $dateTimeNow = Get-Date
                                $initialRunTimeDate = [DateTime]::SpecifyKind($initialRunTime, [DateTimeKind]::Utc)
                                # Correct initial run time if date is in past
                                if ($initialRunTimeDate -lt $dateTimeNow) {
                                    $dateTimeTomorrow = $dateTimeNow.AddHours(24)
                                    $newInitialRunTimeDate = (Get-Date -Day $dateTimeTomorrow.Day -Month $dateTimeTomorrow.Month -Year $dateTimeTomorrow.Year -Hour $initialRunTimeDate.Hour -Minute $initialRunTimeDate.Minute -Second $initialRunTimeDate.Second)
                                    $newInitialRunTimeDate = [DateTime]::SpecifyKind($newInitialRunTimeDate, [DateTimeKind]::Utc)
                                    $initialRunTime = Get-Date -Date $newInitialRunTimeDate -Format o
                                }
                                $parameters.initialRunTime = $initialRunTime
                            }

                            $schedule = [PSCustomObject]$parameters

                            $resource = New-BurpSuiteScheduleItem -SiteId $siteId -ScanConfigurationIds $resolvedScanConfigurationIds -Schedule $schedule
                        }

                        Start-Sleep -Seconds 1
                    }

                    default {
                        throw "Unknown resource type."
                    }
                }

                $provisioningResult = [PSCustomObject]@{
                    Id                = $resource.Id
                    ResourceId        = $InputObject.ResourceId
                    ProvisioningState = [ProvisioningState]::Succeeded
                    Properties        = $resource
                }
            }
        } catch {
            $provisioningResult = [PSCustomObject]@{
                Id                = $resource.Id
                ResourceId        = $InputObject.ResourceId
                ProvisioningState = [ProvisioningState]::Error
                ProvisioningError = $_.Exception.Message.ToString()
                Properties        = $resource
            }
        }

        [DeploymentCache]::Deployments += $provisioningResult
        $provisioningResult
    }

    end {
        [DeploymentCache]::Deployments = @()
    }
}
