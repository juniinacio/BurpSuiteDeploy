InModuleScope $env:BHProjectName {
    Describe "Invoke-BurpSuiteDeployment" {
        Context "BurpSuite folders" {
            BeforeAll {
                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{Id = 0; Name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteFolder" {
                # arrange
                $testDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                $testDeploymentResult = [PSCustomObject]@{
                    Id                = ([guid]::NewGuid()).Guid
                    ResourceId        = $testDeployment.ResourceId
                    ProvisioningState = "Succeeded"
                }

                Mock -CommandName New-BurpSuiteFolder -MockWith {
                    [PSCustomObject]@{
                        Id = $testDeploymentResult.Id
                    }
                }

                # act
                $deployment = Invoke-BurpSuiteDeployment -Deployments $testDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteFolder -ParameterFilter {
                    $ParentId -eq 0 `
                        -and $Name -eq $testDeployment.Name
                }

                $deployment.Id | Should -Be $testDeploymentResult.Id
                $deployment.ResourceId | Should -Be $testDeployment.ResourceId
                $deployment.ProvisioningState | Should -Be $testDeploymentResult.ProvisioningState
            }
        }

        Context "BurpSuite Sites" {
            BeforeAll {
                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{Id = 0; Name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteSite" {
                # arrange
                $testDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)
                $testDeploymentResult = [PSCustomObject]@{
                    Id                = ([guid]::NewGuid()).Guid
                    ResourceId        = $testDeployment.ResourceId
                    ProvisioningState = "Succeeded"
                }

                Mock -CommandName New-BurpSuiteSite -MockWith {
                    [PSCustomObject]@{
                        Id = $testDeploymentResult.Id
                    }
                }

                # act
                $deployment = Invoke-BurpSuiteDeployment -Deployments $testDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteSite -ParameterFilter {
                    $ParentId -eq 0 `
                        -and $Name -eq $testDeployment.Name `
                        -and $Scope.IncludedUrls[0] -eq $testDeployment.Properties.Scope.IncludedUrls[0] `
                        -and $Scope.ExcludedUrls[0] -eq $testDeployment.Properties.Scope.ExcludedUrls[0] `
                        -and $ScanConfigurationIds[0] -eq $testDeployment.Properties.ScanConfigurationIds[0] `
                        -and $EmailRecipients[0].email -eq $testDeployment.Properties.EmailRecipients[0].email `
                        -and $ApplicationLogins[0].label -eq $testDeployment.Properties.ApplicationLogins[0].label `
                        -and $ApplicationLogins[0].username -eq $testDeployment.Properties.ApplicationLogins[0].username `
                        -and $ApplicationLogins[0].password -eq $testDeployment.Properties.ApplicationLogins[0].password
                }

                $deployment.Id | Should -Be $testDeploymentResult.Id
                $deployment.ResourceId | Should -Be $testDeployment.ResourceId
                $deployment.ProvisioningState | Should -Be $testDeploymentResult.ProvisioningState
            }
        }

        Context "BurpSuite Folder Sites" {
            BeforeAll {
                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{Id = 0; Name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteSite" {
                # arrange
                $testDeployments = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderSiteDeploymentType.json | Out-String)
                $testFolderDeploymentResult = [PSCustomObject]@{
                    Id                = ([guid]::NewGuid()).Guid.ToString()
                    ResourceId        = $testDeployments[0].ResourceId
                    ProvisioningState = "Succeeded"
                }
                $testSiteDeploymentResult = [PSCustomObject]@{
                    Id                = ([guid]::NewGuid()).Guid.ToString()
                    ResourceId        = $testDeployments[1].ResourceId
                    ProvisioningState = "Succeeded"
                }

                [DeploymentCache]::Deployments = @()

                Mock -CommandName New-BurpSuiteFolder -MockWith {
                    [PSCustomObject]@{
                        Id = $testFolderDeploymentResult.Id
                    }
                }

                Mock -CommandName New-BurpSuiteSite -MockWith {
                    [PSCustomObject]@{
                        Id = $testSiteDeploymentResult.Id
                    }
                }

                # act
                $deployments = Invoke-BurpSuiteDeployment -Deployments $testDeployments

                # assert
                Should -Invoke -CommandName New-BurpSuiteFolder -ParameterFilter {
                    $ParentId -eq 0 `
                        -and $Name -eq $testDeployments[0].Name
                }

                Should -Invoke -CommandName New-BurpSuiteSite -ParameterFilter {
                    $ParentId -eq $testFolderDeploymentResult.Id `
                        -and $Name -eq $testDeployments[1].Name `
                        -and $Scope.IncludedUrls[0] -eq $testDeployments[1].Properties.scope.includedUrls[0] `
                        -and $Scope.ExcludedUrls[0] -eq $testDeployments[1].Properties.scope.excludedUrls[0] `
                        -and $ScanConfigurationIds[0] -eq $testDeployments[1].Properties.scanConfigurationIds[0] `
                        -and $EmailRecipients[0].email -eq $testDeployments[1].Properties.EmailRecipients[0].email `
                        -and $ApplicationLogins[0].label -eq $testDeployments[1].Properties.ApplicationLogins[0].label `
                        -and $ApplicationLogins[0].username -eq $testDeployments[1].Properties.ApplicationLogins[0].username `
                        # -and $ApplicationLogins[0].password -eq $testDeployments[1].Properties.ApplicationLogins[0].password
                }

                $deployments[0].Id | Should -Be $testFolderDeploymentResult.Id
                $deployments[0].ResourceId | Should -Be $testFolderDeploymentResult.ResourceId
                $deployments[0].ProvisioningState | Should -Be $testFolderDeploymentResult.ProvisioningState

                $deployments[1].Id | Should -Be $testSiteDeploymentResult.Id
                # $deployments[1].ParentId | Should -Be $testFolderDeploymentResult.Id
                $deployments[1].ResourceId | Should -Be $testSiteDeploymentResult.ResourceId
                $deployments[1].ProvisioningState | Should -Be $testSiteDeploymentResult.ProvisioningState
            }
        }

        Context "BurpSuite Scan Configurations" {
            BeforeAll {
                Mock -CommandName Get-BurpSuiteSiteTree -MockWith {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{Id = 0; Name = 'Root' })
                        sites   = @()
                    }
                }

                Mock -CommandName Get-BurpSuiteScanConfiguration -MockWith {
                    $null
                }

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteScanConfiguration" {
                # arrange
                $testDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScanConfigurationDeploymentType.json | Out-String)
                $testDeploymentResult = [PSCustomObject]@{
                    Id                = ([guid]::NewGuid()).Guid
                    ResourceId        = $testDeployment.ResourceId
                    ProvisioningState = "Succeeded"
                }
                $testPath = "TestDrive:\{0}.json" -f [Guid]::NewGuid()
                $testPath = New-Item -Path $testPath -ItemType File

                Mock -CommandName New-BurpSuiteScanConfiguration -MockWith {
                    [PSCustomObject]@{
                        Id = $testDeploymentResult.Id
                    }
                }

                Mock -CommandName _createTempFile -MockWith {
                    Out-File -NoNewline -InputObject $InputObject -FilePath $testPath
                    $testPath
                }

                # act
                $deployment = Invoke-BurpSuiteDeployment -Deployments $testDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteScanConfiguration -ParameterFilter {
                    $Name -eq $testDeployment.Name `
                        -and $FilePath -eq $testPath.FullName
                }

                Should -Invoke -CommandName _createTempFile -ParameterFilter {
                    $InputObject -eq $testDeployment.Properties.scanConfigurationFragmentJson
                }

                $deployment.Id | Should -Be $testDeploymentResult.Id
                $deployment.ResourceId | Should -Be $testDeployment.ResourceId
                $deployment.ProvisioningState | Should -Be $testDeploymentResult.ProvisioningState
            }
        }
    }
}
