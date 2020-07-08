InModuleScope $env:BHProjectName {
    Describe "Invoke-BurpSuiteDeployment" {
        Context "BurpSuite Folders" {
            BeforeAll {
                [DeploymentCache]::Deployments = @()

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{id = ([guid]::NewGuid()).Guid; parent_id = 0; name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                Mock -CommandName Get-BurpSuiteScheduleItem -MockWith {
                    $null
                }

                Mock -CommandName Start-Sleep

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteFolder when resource does not exist" {
                # arrange
                $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testFolder.Id
                $testResult.ResourceId = $testFolderDeployment.ResourceId

                Mock -CommandName New-BurpSuiteFolder -MockWith {
                    [PSCustomObject]@{
                        Id   = $testFolder.Id
                        Name = $testFolder.Name
                    }
                }

                # act
                $deployment = $testFolderDeployment | Invoke-BurpSuiteDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteFolder -ParameterFilter {
                    $ParentId -eq 0 `
                        -and $Name -eq $testFolderDeployment.Name
                }

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            It "should not call New-BurpSuiteFolder when resource exists" {
                # arrange
                $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testFolder.Id
                $testResult.ResourceId = $testFolderDeployment.ResourceId

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @(
                            [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                            $testFolder
                        )
                        sites   = @()
                    }
                }

                Mock -CommandName New-BurpSuiteFolder

                # act
                $deployment = $testFolderDeployment | Invoke-BurpSuiteDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            AfterEach {
                [DeploymentCache]::Deployments = @()
                [ScanConfigurationCache]::ScanConfigurations = @()
                [SiteTreeCache]::SiteTree = $null
            }
        }

        Context "BurpSuite Sites" {
            BeforeAll {
                [DeploymentCache]::Deployments = @()

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{id = ([guid]::NewGuid()).Guid; parent_id = 0; name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                Mock -CommandName Get-BurpSuiteScheduleItem -MockWith {
                    $null
                }

                Mock -CommandName Start-Sleep

                Mock -CommandName New-BurpSuiteSite
                Mock -CommandName Update-BurpSuiteSiteScope
                Mock -CommandName Update-BurpSuiteSiteScanConfiguration
                Mock -CommandName Update-BurpSuiteSiteApplicationLogin
                Mock -CommandName Update-BurpSuiteSiteEmailRecipient
                Mock -CommandName New-BurpSuiteSiteApplicationLogin
                Mock -CommandName New-BurpSuiteSiteEmailRecipient

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteSite when resource does not exist" {
                # arrange
                $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)
                $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testSite.Id
                $testResult.ResourceId = $testSiteDeployment.ResourceId

                Mock -CommandName New-BurpSuiteSite -MockWith {
                    $testSite
                }

                # act
                $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteSite -ParameterFilter {
                    $ParentId -eq 0 `
                        -and $Name -eq $testSiteDeployment.Name `
                        -and $Scope.IncludedUrls[0] -eq $testSiteDeployment.Properties.Scope.IncludedUrls[0] `
                        -and $Scope.ExcludedUrls[0] -eq $testSiteDeployment.Properties.Scope.ExcludedUrls[0] `
                        -and $ScanConfigurationIds[0] -eq $testSiteDeployment.Properties.ScanConfigurationIds[0] `
                        -and $EmailRecipients[0].email -eq $testSiteDeployment.Properties.EmailRecipients[0].email `
                        -and $ApplicationLogins[0].label -eq $testSiteDeployment.Properties.ApplicationLogins[0].label `
                        -and (($ApplicationLogins[0].Credential).GetNetworkCredential()).username -eq $testSiteDeployment.Properties.ApplicationLogins[0].username `
                        -and (($ApplicationLogins[0].Credential).GetNetworkCredential()).password -eq $testSiteDeployment.Properties.ApplicationLogins[0].password
                }

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            It "should not call New-BurpSuiteSite when resource does exist" {
                # arrange
                $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)
                $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testSite.Id
                $testResult.ResourceId = $testSiteDeployment.ResourceId

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @(
                            [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' }
                        )
                        sites   = @(
                            $testSite
                        )
                    }
                }

                Mock -CommandName New-BurpSuiteSite

                # act
                $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            Context "Application Logins" {
                It "should call Update-BurpSuiteSiteApplicationLogin when application login does exist" {
                    # arrange
                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @()

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteApplicationLogin

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteApplicationLogin -ParameterFilter {
                        $Id -eq $testSite.application_logins[0].id `
                            -and $Credential.GetNetworkCredential().UserName -eq $testSiteDeployment.Properties.applicationLogins[0].username `
                            -and $Credential.GetNetworkCredential().Password -eq $testSiteDeployment.Properties.applicationLogins[0].password
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                It "should call New-BurpSuiteSiteApplicationLogin when application login does exist" {
                    # arrange
                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @()

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName New-BurpSuiteSiteApplicationLogin

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName New-BurpSuiteSiteApplicationLogin -ParameterFilter {
                        $SiteId -eq $testSite.id `
                            -and $Label -eq $testSiteDeployment.Properties.applicationLogins[0].label `
                            -and $Credential.GetNetworkCredential().UserName -eq $testSiteDeployment.Properties.applicationLogins[0].username `
                            -and $Credential.GetNetworkCredential().Password -eq $testSiteDeployment.Properties.applicationLogins[0].password
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            Context "Email Recipients" {
                It "should call Update-BurpSuiteSiteEmailRecipient when email recipient does exist" {
                    # arrange
                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @()

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteEmailRecipient

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteEmailRecipient -ParameterFilter {
                        $Id -eq $testSite.email_recipients[0].id `
                            -and $Email -eq $testSiteDeployment.Properties.emailRecipients[0].email
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                It "should call New-BurpSuiteSiteEmailRecipient when email recipient does exist" {
                    # arrange
                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @()

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName New-BurpSuiteSiteEmailRecipient

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName New-BurpSuiteSiteEmailRecipient -ParameterFilter {
                        $SiteId -eq $testSite.id `
                            -and $EmailRecipient -eq $testSiteDeployment.Properties.emailRecipients[0].email
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            Context "Scopes" {
                It "should call Update-BurpSuiteSiteScope when resource does exist" {
                    # arrange
                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)
                    $testSite.scan_configurations = $null
                    $testSite.application_logins = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @()

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteScope

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteScope -ParameterFilter {
                        $SiteId -eq $testSite.id `
                            -and $IncludedUrls[0] -eq $testSiteDeployment.Properties.scope.includedUrls[0] `
                            -and $ExcludedUrls[0] -eq $testSiteDeployment.Properties.scope.excludedUrls[0]
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            Context "Scan Configurations" {
                It "should call Update-BurpSuiteSiteScanConfiguration when resource does exist" {
                    # arrange
                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @()

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteScanConfiguration

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteScanConfiguration -ParameterFilter {
                        $Id -eq $testSite.id `
                            -and $ScanConfigurationIds[0] -eq $testSiteDeployment.Properties.scanConfigurationIds[0]
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            Context "Resolve Expressions" {
                It "should resolve reference expression for scan configurations" {
                    # arrange
                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\Expressions.json | Out-String)
                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)

                    $testScanConfigurationResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testScanConfigurationResult.ResourceId = "BurpSuite/ScanConfigurations/Example - Large Scan Configuration"

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @(
                        $testScanConfigurationResult
                    )

                    Mock -CommandName New-BurpSuiteSite -MockWith {
                        $testSite
                    }

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteSite -ParameterFilter {
                        $ParentId -eq 0 `
                            -and $Name -eq $testSiteDeployment.Name `
                            -and $Scope.IncludedUrls[0] -eq $testSiteDeployment.Properties.Scope.IncludedUrls[0] `
                            -and $Scope.ExcludedUrls[0] -eq $testSiteDeployment.Properties.Scope.ExcludedUrls[0] `
                            -and $ScanConfigurationIds[0] -eq $testScanConfigurationResult.id `
                            -and $EmailRecipients[0].email -eq $testSiteDeployment.Properties.EmailRecipients[0].email `
                            -and $ApplicationLogins[0].label -eq $testSiteDeployment.Properties.ApplicationLogins[0].label `
                            -and (($ApplicationLogins[0].Credential).GetNetworkCredential()).username -eq $testSiteDeployment.Properties.ApplicationLogins[0].username `
                            -and (($ApplicationLogins[0].Credential).GetNetworkCredential()).password -eq $testSiteDeployment.Properties.ApplicationLogins[0].password
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            AfterEach {
                [DeploymentCache]::Deployments = @()
                [ScanConfigurationCache]::ScanConfigurations = @()
                [SiteTreeCache]::SiteTree = $null
            }
        }

        Context "BurpSuite Folder Sites" {
            BeforeAll {
                [DeploymentCache]::Deployments = @()

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{id = ([guid]::NewGuid()).Guid; parent_id = 0; name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                Mock -CommandName Get-BurpSuiteScheduleItem -MockWith {
                    $null
                }

                Mock -CommandName Start-Sleep

                Mock -CommandName Update-BurpSuiteSiteScope
                Mock -CommandName Update-BurpSuiteSiteScanConfiguration
                Mock -CommandName Update-BurpSuiteSiteApplicationLogin
                Mock -CommandName Update-BurpSuiteSiteEmailRecipient
                Mock -CommandName New-BurpSuiteSiteApplicationLogin
                Mock -CommandName New-BurpSuiteSiteEmailRecipient


                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteSite when resource does not exist" {
                # arrange
                $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                $testFolderResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testFolderResult.Id = $testFolder.Id
                $testFolderResult.ResourceId = $testFolderDeployment.ResourceId

                $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)
                $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testSite.Id
                $testResult.ResourceId = $testSiteDeployment.ResourceId

                [DeploymentCache]::Deployments = @(
                    $testFolderResult
                )

                Mock -CommandName New-BurpSuiteSite -MockWith {
                    $testSite
                }

                # act
                $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                Should -Invoke -CommandName New-BurpSuiteSite -ParameterFilter {
                    $ParentId -eq $testFolderResult.Id `
                        -and $Name -eq $testSiteDeployment.Name `
                        -and $Scope.IncludedUrls[0] -eq $testSiteDeployment.Properties.scope.includedUrls[0] `
                        -and $Scope.ExcludedUrls[0] -eq $testSiteDeployment.Properties.scope.excludedUrls[0] `
                        -and $ScanConfigurationIds[0] -eq $testSiteDeployment.Properties.scanConfigurationIds[0] `
                        -and $EmailRecipients[0].email -eq $testSiteDeployment.Properties.EmailRecipients[0].email `
                        -and $ApplicationLogins[0].label -eq $testSiteDeployment.Properties.ApplicationLogins[0].label `
                        -and (($ApplicationLogins[0].Credential).GetNetworkCredential()).username -eq $testSiteDeployment.Properties.ApplicationLogins[0].username `
                        -and (($ApplicationLogins[0].Credential).GetNetworkCredential()).password -eq $testSiteDeployment.Properties.ApplicationLogins[0].password
                }

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            Context "Application Logins" {
                It "should call Update-BurpSuiteSiteApplicationLogin when application login does exist" {
                    # arrange
                    $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                    $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                    $testFolderResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testFolderResult.Id = $testFolder.Id
                    $testFolderResult.ResourceId = $testFolderDeployment.ResourceId

                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteReturnType.json | Out-String)
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @(
                        $testFolderResult
                    )

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteApplicationLogin

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteApplicationLogin -ParameterFilter {
                        $Id -eq $testSite.application_logins[0].id `
                            -and $Credential.GetNetworkCredential().UserName -eq $testSiteDeployment.Properties.applicationLogins[0].username `
                            -and $Credential.GetNetworkCredential().Password -eq $testSiteDeployment.Properties.applicationLogins[0].password
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                It "should call New-BurpSuiteSiteApplicationLogin when application login does exist" {
                    # arrange
                    $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                    $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                    $testFolderResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testFolderResult.Id = $testFolder.Id
                    $testFolderResult.ResourceId = $testFolderDeployment.ResourceId

                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @(
                        $testFolderResult
                    )

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName New-BurpSuiteSiteApplicationLogin

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName New-BurpSuiteSiteApplicationLogin -ParameterFilter {
                        $SiteId -eq $testSite.id `
                            -and $Label -eq $testSiteDeployment.Properties.applicationLogins[0].label `
                            -and $Credential.GetNetworkCredential().UserName -eq $testSiteDeployment.Properties.applicationLogins[0].username `
                            -and $Credential.GetNetworkCredential().Password -eq $testSiteDeployment.Properties.applicationLogins[0].password
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            Context "Email Recipients" {
                It "should call Update-BurpSuiteSiteEmailRecipient when email recipient does exist" {
                    # arrange
                    $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                    $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                    $testFolderResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testFolderResult.Id = $testFolder.Id
                    $testFolderResult.ResourceId = $testFolderDeployment.ResourceId

                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @(
                        $testFolderResult
                    )

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteEmailRecipient

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteEmailRecipient -ParameterFilter {
                        $Id -eq $testSite.email_recipients[0].id `
                            -and $Email -eq $testSiteDeployment.Properties.emailRecipients[0].email
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                It "should call New-BurpSuiteSiteEmailRecipient when email recipient does exist" {
                    # arrange
                    $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                    $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                    $testFolderResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testFolderResult.Id = $testFolder.Id
                    $testFolderResult.ResourceId = $testFolderDeployment.ResourceId

                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.scope = $null
                    $testSite.scan_configurations = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @(
                        $testFolderResult
                    )

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName New-BurpSuiteSiteEmailRecipient

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName New-BurpSuiteSiteEmailRecipient -ParameterFilter {
                        $SiteId -eq $testSite.id `
                            -and $EmailRecipient -eq $testSiteDeployment.Properties.emailRecipients[0].email
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            Context "Scopes" {
                It "should call Update-BurpSuiteSiteScope when resource does exist" {
                    # arrange
                    $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                    $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                    $testFolderResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testFolderResult.Id = $testFolder.Id
                    $testFolderResult.ResourceId = $testFolderDeployment.ResourceId

                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteReturnType.json | Out-String)
                    $testSite.scan_configurations = $null
                    $testSite.application_logins = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @(
                        $testFolderResult
                    )

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteScope

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteScope -ParameterFilter {
                        $SiteId -eq $testSite.id `
                            -and $IncludedUrls[0] -eq $testSiteDeployment.Properties.scope.includedUrls[0] `
                            -and $ExcludedUrls[0] -eq $testSiteDeployment.Properties.scope.excludedUrls[0]
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }

            Context "Scan Configurations" {
                It "should call Update-BurpSuiteSiteScanConfiguration when resource does exist" {
                    # arrange
                    $testFolderDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                    $testFolder = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderReturnType.json | Out-String)

                    $testFolderResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testFolderResult.Id = $testFolder.Id
                    $testFolderResult.ResourceId = $testFolderDeployment.ResourceId

                    $testSiteDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)

                    $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteReturnType.json | Out-String)
                    $testSite.application_logins = $null
                    $testSite.email_recipients = $null

                    $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                    $testResult.Id = $testSite.Id
                    $testResult.ResourceId = $testSiteDeployment.ResourceId

                    [DeploymentCache]::Deployments = @(
                        $testFolderResult
                    )

                    Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                        [PSCustomObject]@{
                            folders = @(
                                [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                                $testFolder
                            )
                            sites   = @(
                                $testSite
                            )
                        }
                    }

                    Mock -CommandName New-BurpSuiteFolder
                    Mock -CommandName New-BurpSuiteSite
                    Mock -CommandName Update-BurpSuiteSiteScanConfiguration

                    # act
                    $deployment = $testSiteDeployment | Invoke-BurpSuiteDeployment

                    # assert
                    Should -Invoke -CommandName New-BurpSuiteFolder -Times 0 -Scope It
                    Should -Invoke -CommandName New-BurpSuiteSite -Times 0 -Scope It

                    Should -Invoke -CommandName Update-BurpSuiteSiteScanConfiguration -ParameterFilter {
                        $Id -eq $testSite.id `
                            -and $ScanConfigurationIds[0] -eq $testSiteDeployment.Properties.scanConfigurationIds[0]
                    }

                    $deployment.Id | Should -Be $testResult.Id
                    $deployment.ResourceId | Should -Be $testResult.ResourceId
                    $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
                }

                AfterEach {
                    [DeploymentCache]::Deployments = @()
                    [ScanConfigurationCache]::ScanConfigurations = @()
                    [SiteTreeCache]::SiteTree = $null
                }
            }
        }

        Context "BurpSuite Scan Configurations" {
            BeforeAll {
                [DeploymentCache]::Deployments = @()
                [ScanConfigurationCache]::ScanConfigurations = @()

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{id = ([guid]::NewGuid()).Guid; parent_id = 0; name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                Mock -CommandName Get-BurpSuiteScheduleItem -MockWith {
                    $null
                }

                Mock -CommandName Start-Sleep

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteScanConfiguration when resource does not exist" {
                # arrange
                $testScanConfigurationDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScanConfigurationDeploymentType.json | Out-String)
                $testScanConfiguration = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScanConfigurationReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testScanConfiguration.Id
                $testResult.ResourceId = $testScanConfigurationDeployment.ResourceId

                $testPath = "TestDrive:\{0}.json" -f [Guid]::NewGuid()
                $testPath = New-Item -Path $testPath -ItemType File

                Mock -CommandName New-BurpSuiteScanConfiguration -MockWith {
                    $testScanConfiguration
                }

                Mock -CommandName _createTempFile -MockWith {
                    Out-File -NoNewline -InputObject $InputObject -FilePath $testPath
                    $testPath
                }

                # act
                $deployment = $testScanConfigurationDeployment | Invoke-BurpSuiteDeployment

                # assert
                Should -Invoke -CommandName _createTempFile -ParameterFilter {
                    $InputObject -eq $testScanConfigurationDeployment.Properties.scanConfigurationFragmentJson
                }

                Should -Invoke -CommandName New-BurpSuiteScanConfiguration -ParameterFilter {
                    $Name -eq $testScanConfigurationDeployment.Name `
                        -and $FilePath -eq $testPath.FullName
                }

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            It "should call Update-BurpSuiteScanConfiguration when resource does exist" {
                # arrange
                $testScanConfigurationDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScanConfigurationDeploymentType.json | Out-String)
                $testScanConfiguration = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScanConfigurationReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testScanConfiguration.Id
                $testResult.ResourceId = $testScanConfigurationDeployment.ResourceId

                $testPath = "TestDrive:\{0}.json" -f [Guid]::NewGuid()
                $testPath = New-Item -Path $testPath -ItemType File

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $testScanConfiguration
                }

                [ScanConfigurationCache]::ScanConfigurations = @(
                    $testScanConfiguration
                )

                Mock -CommandName New-BurpSuiteScanConfiguration

                Mock -CommandName Update-BurpSuiteScanConfiguration

                Mock -CommandName _createTempFile -MockWith {
                    Out-File -NoNewline -InputObject $InputObject -FilePath $testPath
                    $testPath
                }

                # act
                $deployment = $testScanConfigurationDeployment | Invoke-BurpSuiteDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteScanConfiguration -Times 0 -Scope It

                Should -Invoke -CommandName _createTempFile -ParameterFilter {
                    $InputObject -eq $testScanConfigurationDeployment.Properties.scanConfigurationFragmentJson
                }

                Should -Invoke Update-BurpSuiteScanConfiguration -ParameterFilter {
                    $Id -eq $testResult.Id `
                        -and $FilePath -eq $testPath.FullName
                }

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testScanConfigurationDeployment.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            AfterEach {
                [DeploymentCache]::Deployments = @()
                [ScanConfigurationCache]::ScanConfigurations = @()
            }
        }

        Context "BurpSuite Schedule Items" {
            BeforeAll {
                [DeploymentCache]::Deployments = @()

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{id = ([guid]::NewGuid()).Guid; parent_id = 0; name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                Mock -CommandName Get-BurpSuiteScheduleItem -MockWith {
                    $null
                }

                Mock -CommandName Start-Sleep

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "It should call New-BurpSuiteScheduleItem when resource does not exist" {
                # arrange
                $testSiteResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)
                $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)

                $testScheduleDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScheduleItemDeploymentType.json | Out-String)

                $testSchedule = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScheduleItemReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testSchedule.Id
                $testResult.ResourceId = $testScheduleDeployment.ResourceId

                [DeploymentCache]::Deployments = @(
                    $testSiteResult
                )

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @(
                            [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                            $testFolder
                        )
                        sites   = @(
                            $testSite
                        )
                    }
                }

                Mock -CommandName New-BurpSuiteScheduleItem -MockWith {
                    $testSchedule
                }

                # act
                $deployment = $testScheduleDeployment | Invoke-BurpSuiteDeployment

                Should -Invoke -CommandName New-BurpSuiteScheduleItem -ParameterFilter {
                    $SiteId -eq $testScheduleDeployment.Properties.siteId `
                        -and $ScanConfigurationIds[0] -eq $testScheduleDeployment.Properties.scanConfigurationIds[0] `
                        -and $Schedule.InitialRunTime -gt (Get-Date -Date $testScheduleDeployment.Properties.schedule.initialRunTime) ` # TODO: Update assertion
                        -and $Schedule.RRule -eq $testScheduleDeployment.Properties.schedule.rRule
                }

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            It "It should call not New-BurpSuiteScheduleItem when resource does exist" {
                # arrange
                $testSiteResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)
                $testSite = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteReturnType.json | Out-String)

                $testScheduleDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScheduleItemDeploymentType.json | Out-String)

                $testSchedule = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScheduleItemReturnType.json | Out-String)

                $testResult = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\DeploymentResultType.json | Out-String)
                $testResult.Id = $testSchedule.Id
                $testResult.ResourceId = $testScheduleDeployment.ResourceId

                [DeploymentCache]::Deployments = @(
                    $testSiteResult
                )

                Mock -CommandName Get-BurpSuiteScheduleItem -MockWith {
                    $testSchedule
                }

                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @(
                            [PSCustomObject]@{id = [guid]::NewGuid(); parent_id = 0; name = 'Root' },
                            $testFolder
                        )
                        sites   = @(
                            $testSite
                        )
                    }
                }

                Mock -CommandName New-BurpSuiteScheduleItem

                # act
                $deployment = $testScheduleDeployment | Invoke-BurpSuiteDeployment

                Should -Invoke -CommandName New-BurpSuiteScheduleItem -Times 0 -Scope It

                $deployment.Id | Should -Be $testResult.Id
                $deployment.ResourceId | Should -Be $testResult.ResourceId
                $deployment.ProvisioningState | Should -Be $testResult.ProvisioningState
            }

            AfterEach {
                [DeploymentCache]::Deployments = @()
                [SiteTreeCache]::SiteTree = $null
            }
        }
    }
}
