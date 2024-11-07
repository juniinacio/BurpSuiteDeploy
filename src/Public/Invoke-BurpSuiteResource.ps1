function Invoke-BurpSuiteResource {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding(SupportsShouldProcess = $true,
        HelpUri = 'https://github.com/juniinacio/BurpSuiteDeploy',
        ConfirmImpact = 'Medium')]
    Param (
        [parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [object]$InputObject
    )

    begin {
        [SiteTreeCache]::Init()
        [ScanConfigurationCache]::Init()
        [ScheduleItemCache]::Init()
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
                                ScopeV2              = $InputObject.Properties.scopeV2
                                ScanConfigurationIds = $scanConfigurationIds
                            }

                            if ($null -ne ($InputObject.Properties.emailRecipients)) {
                                $parameters.EmailRecipients = $InputObject.Properties.emailRecipients
                            }

                            if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                if ($null -ne ($InputObject.Properties.applicationLogins.loginCredentials)) {
                                    $loginCredentials = @()

                                    foreach ($loginCredential in $InputObject.Properties.applicationLogins.loginCredentials) {
                                        $loginCredentials += [PSCustomObject]@{ Label = $loginCredential.Label; Credential = (New-Object System.Management.Automation.PSCredential ($loginCredential.Username, $(ConvertTo-SecureString $loginCredential.Password -AsPlainText -Force))) }
                                    }

                                    $parameters.LoginCredentials = $loginCredentials
                                }

                                if ($null -ne ($InputObject.Properties.applicationLogins.recordedLogins)) {
                                    $recordedLogins = @()

                                    foreach ($recordedLogin in $InputObject.Properties.applicationLogins.recordedLogins) {
                                        $recordedLogins += [PSCustomObject]@{ Label = $recordedLogin.Label; FilePath = (_createTempFile -InputObject $recordedLogin.script).FullName }
                                    }

                                    $parameters.RecordedLogins = $recordedLogins
                                }
                            }

                            $resource = New-BurpSuiteSite @parameters

                            [SiteTreeCache]::Reload()
                        } else {

                            Write-Verbose "Updating site $($InputObject.Name)`..."

                            if ($null -ne ($InputObject.Properties.scopeV2)) {
                                Write-Verbose " Updating site scopes..."

                                $parameters = @{
                                    StartUrls             = @($InputObject.Properties.scopeV2.startUrls)
                                    InScopeUrlPrefixes    = @($InputObject.Properties.scopeV2.inScopeUrlPrefixes)
                                    OutOfScopeUrlPrefixes = @($InputObject.Properties.scopeV2.outOfScopeUrlPrefixes)
                                }

                                if ($null -ne ($InputObject.Properties.scopeV2.protocolOptions)) { $parameters.ProtocolOptions = $InputObject.Properties.scopeV2.protocolOptions }

                                Update-BurpSuiteSiteScope -SiteId $resource.Id @parameters

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

                            [SiteTreeCache]::Reload()
                            $resource = [SiteTreeCache]::Get(0, $InputObject.Name, 'Sites')

                            if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                if ($null -ne ($InputObject.Properties.applicationLogins.loginCredentials)) {
                                    Write-Verbose " Updating application logins..."
                                    foreach ($loginCredential in $InputObject.Properties.applicationLogins.loginCredentials) {
                                        $appPass = ConvertTo-SecureString -String $loginCredential.password -AsPlainText -Force
                                        $appCredential = New-Object -TypeName PSCredential -ArgumentList $loginCredential.username, $appPass
                                        $appLogin = $resource.application_logins.login_credentials | Where-Object { $_.label -eq $loginCredential.label }
                                        if ($null -eq $appLogin) {
                                            New-BurpSuiteSiteLoginCredential -SiteId $resource.id -Label $loginCredential.label -Credential $appCredential | Out-Null
                                        } else {
                                            Update-BurpSuiteSiteLoginCredential -Id $appLogin.id -Credential $appCredential
                                        }
                                        Start-Sleep -Seconds 1
                                    }
                                }

                                if ($null -ne ($InputObject.Properties.applicationLogins.recordedLogins)) {
                                    Write-Verbose " Updating recorded logins..."
                                    foreach ($recordedLogin in $InputObject.Properties.applicationLogins.recordedLogins) {
                                        $appLogin = $resource.application_logins.recorded_logins | Where-Object { $_.label -eq $recordedLogin.label }
                                        if ($null -eq $appLogin) {
                                            New-BurpSuiteSiteRecordedLogin -SiteId $resource.id -Label $recordedLogin.label -FilePath (_createTempFile -InputObject $recordedLogin.script).FullName | Out-Null
                                        }
                                        Start-Sleep -Seconds 1
                                    }
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
                            [SiteTreeCache]::Reload()
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
                                    ScopeV2              = $InputObject.Properties.scopeV2
                                    ScanConfigurationIds = $scanConfigurationIds
                                }

                                if ($null -ne ($InputObject.Properties.emailRecipients)) {
                                    $parameters.EmailRecipients = $InputObject.Properties.emailRecipients
                                }

                                if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                    if ($null -ne ($InputObject.Properties.applicationLogins.loginCredentials)) {
                                        $loginCredentials = @()

                                        foreach ($loginCredential in $InputObject.Properties.applicationLogins.loginCredentials) {
                                            $loginCredentials += [PSCustomObject]@{ Label = $loginCredential.Label; Credential = (New-Object System.Management.Automation.PSCredential ($loginCredential.Username, $(ConvertTo-SecureString $loginCredential.Password -AsPlainText -Force))) }
                                        }

                                        $parameters.LoginCredentials = $loginCredentials
                                    }

                                    if ($null -ne ($InputObject.Properties.applicationLogins.recordedLogins)) {
                                        $recordedLogins = @()

                                        foreach ($recordedLogin in $InputObject.Properties.applicationLogins.recordedLogins) {
                                            $recordedLogins += [PSCustomObject]@{ Label = $recordedLogin.Label; FilePath = (_createTempFile -InputObject $recordedLogin.script).FullName }
                                        }

                                        $parameters.RecordedLogins = $recordedLogins
                                    }
                                }

                                $resource = New-BurpSuiteSite @parameters

                                [SiteTreeCache]::Reload()
                            } else {
                                Write-Verbose "Updating site $($InputObject.Name), parent id $($parentResource.Id)`..."

                                if ($null -ne ($InputObject.Properties.scopeV2)) {
                                    Write-Verbose " Updating site scopes..."

                                    $parameters = @{
                                        StartUrls             = @($InputObject.Properties.scopeV2.startUrls)
                                        InScopeUrlPrefixes    = @($InputObject.Properties.scopeV2.inScopeUrlPrefixes)
                                        OutOfScopeUrlPrefixes = @($InputObject.Properties.scopeV2.outOfScopeUrlPrefixes)
                                    }

                                    if ($null -ne ($InputObject.Properties.scopeV2.protocolOptions)) { $parameters.ProtocolOptions = $InputObject.Properties.scopeV2.protocolOptions }

                                    Update-BurpSuiteSiteScope -SiteId $resource.Id @parameters

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

                                [SiteTreeCache]::Reload()
                                $resource = [SiteTreeCache]::Get($parentResource.Id, $InputObject.Name, 'Sites')

                                if ($null -ne ($InputObject.Properties.applicationLogins)) {
                                    if ($null -ne ($InputObject.Properties.applicationLogins.loginCredentials)) {
                                        Write-Verbose " Updating application logins..."
                                        foreach ($loginCredential in $InputObject.Properties.applicationLogins.loginCredentials) {
                                            $appPass = ConvertTo-SecureString -String $loginCredential.password -AsPlainText -Force
                                            $appCredential = New-Object -TypeName PSCredential -ArgumentList $loginCredential.username, $appPass
                                            $appLogin = $resource.application_logins.login_credentials | Where-Object { $_.label -eq $loginCredential.label }
                                            if ($null -eq $appLogin) {
                                                New-BurpSuiteSiteLoginCredential -SiteId $resource.id -Label $loginCredential.label -Credential $appCredential | Out-Null
                                            } else {
                                                Update-BurpSuiteSiteLoginCredential -Id $appLogin.id -Credential $appCredential
                                            }
                                            Start-Sleep -Seconds 1
                                        }
                                    }

                                    if ($null -ne ($InputObject.Properties.applicationLogins.recordedLogins)) {
                                        Write-Verbose " Updating recorded logins..."
                                        foreach ($recordedLogin in $InputObject.Properties.applicationLogins.recordedLogins) {
                                            $appLogin = $resource.application_logins.recorded_logins | Where-Object { $_.label -eq $recordedLogin.label }
                                            if ($null -eq $appLogin) {
                                                New-BurpSuiteSiteRecordedLogin -SiteId $resource.id -Label $recordedLogin.label -FilePath (_createTempFile -InputObject $recordedLogin.script).FullName | Out-Null
                                            }
                                            Start-Sleep -Seconds 1
                                        }
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
                            [ScanConfigurationCache]::Reload()
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

                            [ScheduleItemCache]::Reload()
                        }

                        Start-Sleep -Seconds 1
                    }

                    default {
                        throw "Unknown resource type."
                    }
                }

                $deployment = [Deployment]@{
                    Id                = $resource.Id
                    ResourceId        = $InputObject.ResourceId
                    ProvisioningState = [ProvisioningState]::Succeeded
                    Properties        = $resource
                }
            }
        } catch {
            $deployment = [Deployment]@{
                Id                = $resource.Id
                ResourceId        = $InputObject.ResourceId
                ProvisioningState = [ProvisioningState]::Error
                ProvisioningError = $_.Exception.Message.ToString()
                Properties        = $resource
            }
        }

        [DeploymentCache]::Set($deployment)

        $deployment
    }

    end {
        [DeploymentCache]::Init()
    }
}
