InModuleScope $env:BHProjectName {
    Describe "Invoke-BurpSuiteDeployment" {
        Context "BurpSuite folders" {
            BeforeAll {
                function New-BurpSuiteFolder ($ParentId, $Name) {}
                function Get-BurpSuiteScanConfiguration () {}
                function Get-BurpSuiteSiteTree () {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{Id = 0;Name = 'Root'})
                        sites = @()
                    }
                }
                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteFolder" {
                # arrange
                $testDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\FolderDeploymentType.json | Out-String)
                $testDeploymentResult = [PSCustomObject]@{
                    Id = ([guid]::NewGuid()).Guid
                    ResourceId        = $testDeployment.ResourceId
                    ProvisioningState = "Succeeded"
                }

                Mock -CommandName New-BurpSuiteFolder -MockWith {
                    [PSCustomObject]@{
                        Id = $testDeploymentResult.Id
                    }
                }

                # act
                $deployment = Invoke-BurpSuiteDeployment -Deployment $testDeployment

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
                function New-BurpSuiteSite ($Name, $ParentId, [string[]]$IncludedUrls, [string[]]$ExcludedUrls, [string[]]$ScanConfigurationIds, [string[]]$EmailRecipients) {}
                function Get-BurpSuiteScanConfiguration () {}

                function Get-BurpSuiteSiteTree () {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{Id = 0;Name = 'Root'})
                        sites = @()
                    }
                }

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuite" {
                # arrange
                $testDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\SiteDeploymentType.json | Out-String)
                $testDeploymentResult = [PSCustomObject]@{
                    Id = ([guid]::NewGuid()).Guid
                    ResourceId        = $testDeployment.ResourceId
                    ProvisioningState = "Succeeded"
                }

                Mock -CommandName New-BurpSuiteSite -MockWith {
                    [PSCustomObject]@{
                        Id = $testDeploymentResult.Id
                    }
                }

                # act
                $deployment = Invoke-BurpSuiteDeployment -Deployment $testDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteSite -ParameterFilter {
                    $ParentId -eq 0 `
                    -and $Name -eq $testDeployment.Name `
                    -and ($IncludedUrls -join ',') -eq ($testDeployment.Properties.Scope.IncludedUrls -join ',') `
                    -and ($ExcludedUrls -join ',') -eq ($testDeployment.Properties.Scope.ExcludedUrls -join ',') `
                    -and ($ScanConfigurationIds -join ',') -eq ($testDeployment.Properties.ScanConfigurationIds -join ',') `
                    # -and ($EmailRecipients -join ',') -eq ($testDeployment.Properties.EmailRecipients.email -join ',')
                }

                $deployment.Id | Should -Be $testDeploymentResult.Id
                $deployment.ResourceId | Should -Be $testDeployment.ResourceId
                $deployment.ProvisioningState | Should -Be $testDeploymentResult.ProvisioningState
            }
        }

        Context "BurpSuite Scan Configurations" {
            BeforeAll {
                function New-BurpSuiteScanConfiguration ($Name, $FilePath) {}
                function Get-BurpSuiteScanConfiguration () {}
                function Get-BurpSuiteSiteTree () {
                    [PSCustomObject]@{
                        folders = @([PSCustomObject]@{Id = 0;Name = 'Root'})
                        sites = @()
                    }
                }

                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
            }

            It "should call New-BurpSuiteScanConfiguration" {
                # arrange
                $testDeployment = ConvertFrom-Json -InputObject (Get-Content -Path $testArtifacts\ScanConfigurationDeploymentType.json | Out-String)
                $testDeploymentResult = [PSCustomObject]@{
                    Id = ([guid]::NewGuid()).Guid
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

                Mock -CommandName CreateTempFile -MockWith {
                    Out-File -NoNewline -InputObject $InputObject -FilePath $testPath
                    $testPath
                }

                # act
                $deployment = Invoke-BurpSuiteDeployment -Deployment $testDeployment

                # assert
                Should -Invoke -CommandName New-BurpSuiteScanConfiguration -ParameterFilter {
                    $Name -eq $testDeployment.Name `
                    -and $FilePath -eq $testPath.FullName
                }

                Should -Invoke -CommandName CreateTempFile -ParameterFilter {
                    $InputObject -eq $testDeployment.Properties.scanConfigurationFragmentJson
                }

                $deployment.Id | Should -Be $testDeploymentResult.Id
                $deployment.ResourceId | Should -Be $testDeployment.ResourceId
                $deployment.ProvisioningState | Should -Be $testDeploymentResult.ProvisioningState
            }
        }
    }
}
