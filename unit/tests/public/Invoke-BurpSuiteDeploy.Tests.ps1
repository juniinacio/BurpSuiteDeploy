InModuleScope $env:BHProjectName {
    Describe "Invoke-BurpSuiteDeploy" {
        Context "Authenticating to BurpSuite" {
            BeforeAll {
                function Connect-BurpSuite ($Uri, $APIKey) { }
                function Disconnect-BurpSuite { }

                Mock -CommandName Get-BurpSuiteDeployment -MockWith {}
                Mock -CommandName Invoke-BurpSuiteDeployment -MockWith {
                    [PSCustomObject]@{
                        Id                = 1
                        ResourceId        = 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration'
                        ProvisioningState = [ProvisioningState]::Succeeded
                    }
                }

                $testTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts\AllResourceTypes.json'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should call to Connect-BurpSuite" {
                # arrange
                Mock -CommandName Connect-BurpSuite

                # act
                Invoke-BurpSuiteDeploy -TemplateFile $testTemplateFile -Uri $testUri  -APIkey $testKey

                # assert
                Should -Invoke Connect-BurpSuite -ParameterFilter {
                    $Uri -eq $testUri -and $APIKey -eq $testKey
                }
            }

            It "should call Disconnect-BurpSuite" {
                # arrange
                Mock -CommandName Disconnect-BurpSuite -Verifiable
                Mock -CommandName Invoke-BurpSuiteDeployment -MockWith {
                    $deploymentResult = [PSCustomObject]@{
                        Id                = 1
                        ResourceId        = 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration'
                        ProvisioningState = [ProvisioningState]::Succeeded
                    }
                }

                # act
                Invoke-BurpSuiteDeploy -TemplateFile $testTemplateFile -Uri $testUri  -APIkey $testKey

                # assert
                Should -InvokeVerifiable
            }
        }

        Context "Dependencies" {
            BeforeAll {
                function Connect-BurpSuite ($Uri, $APIKey) { }
                function Disconnect-BurpSuite { }

                Mock -CommandName Get-BurpSuiteDeployment -MockWith {}

                Mock -CommandName Invoke-BurpSuiteDeployment -MockWith {
                    $deploymentResult = [PSCustomObject]@{
                        Id                = 1
                        ResourceId        = 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration'
                        ProvisioningState = [ProvisioningState]::Succeeded
                    }
                }

                $testTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts\AllResourceTypes.json'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should call Get-BurpSuiteDeployment" {
                # arrange
                Mock -CommandName Get-BurpSuiteDeployment

                # act
                Invoke-BurpSuiteDeploy -TemplateFile $testTemplateFile -Uri $testUri  -APIkey $testKey

                # assert
                Should -Invoke -CommandName Get-BurpSuiteDeployment -ParameterFilter {
                    $TemplateFile -eq $testTemplateFile
                }
            }
        }

        Context "Deploying resources" {
            BeforeAll {
                function Connect-BurpSuite ($Uri, $APIKey) { }
                function Disconnect-BurpSuite { }

                Mock -CommandName Get-BurpSuiteDeployment -MockWith {}

                $testTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts\AllResourceTypes.json'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should call Invoke-BurpSuiteDeployment" {
                # arrange
                Mock -CommandName Get-BurpSuiteDeployment -MockWith {
                    $objects = @()

                    $objects += [PSCustomObject]@{
                        ResourceId = 'BurpSuite/Folders/Example.com'
                        Properties = @{
                            parentId = "0"
                        }
                    }

                    $objects += [PSCustomObject]@{
                        ResourceId = 'BurpSuite/Sites/root.example.com'
                        Properties = @{
                            parentId = "0"
                        }
                    }

                    $objects += [PSCustomObject]@{
                        ResourceId = 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration'
                        Properties = @{
                            parentId = "0"
                        }
                    }

                    $objects
                }
                Mock -CommandName Invoke-BurpSuiteDeployment -MockWith {
                    [PSCustomObject]@{
                        ResourceId        = $Deployment.ResourceId
                        Properties        = @{
                            parentId = $Deployment.ParentId
                        }
                        ProvisioningState = "Succeeded"
                    }
                }

                # act
                Invoke-BurpSuiteDeploy -TemplateFile $testTemplateFile -Uri $testUri  -APIkey $testKey

                # assert
                Should -Invoke Invoke-BurpSuiteDeployment -ParameterFilter {
                    $Deployments[0].ResourceId -eq 'BurpSuite/Folders/Example.com' `
                        -and $Deployments[0].Properties.ParentId -eq 0
                }

                Should -Invoke Invoke-BurpSuiteDeployment -ParameterFilter {
                    $Deployments[0].ResourceId -eq 'BurpSuite/Sites/root.example.com' `
                        -and $Deployments[0].Properties.ParentId -eq 0
                }

                Should -Invoke Invoke-BurpSuiteDeployment -ParameterFilter {
                    $Deployments[0].ResourceId -eq 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration' `
                        -and $Deployments[0].Properties.ParentId -eq 0
                }
            }

            It "should return deployment objects" {
                # arrange
                Mock -CommandName Get-BurpSuiteDeployment -MockWith {
                    $objects = @()

                    $objects += [PSCustomObject]@{
                        ResourceId = 'BurpSuite/Folders/Example.com'
                        Properties = @{
                            parentId = "0"
                        }
                    }

                    $objects
                }

                Mock -CommandName Invoke-BurpSuiteDeployment -MockWith {
                    $objects = @()

                    $objects += [PSCustomObject]@{
                        ResourceId        = 'BurpSuite/Folders/Example.com'
                        Properties        = @{
                            parentId = "0"
                        }
                        ProvisioningState = [ProvisioningState]::Succeeded
                    }

                    $objects
                }

                # act
                $assert = Invoke-BurpSuiteDeploy -TemplateFile $testTemplateFile -Uri $testUri  -APIkey $testKey

                $assert[0].ResourceId | Should -Be 'BurpSuite/Folders/Example.com'
                $assert[0].ProvisioningState | Should -Be 'Succeeded'
            }

            It "should throw exception when deployments failes" {
                # arrange
                Mock -CommandName Get-BurpSuiteDeployment -MockWith {
                    $objects = @()

                    $objects += [PSCustomObject]@{
                        ResourceId = 'BurpSuite/Folders/Example.com'
                        Properties = @{
                            parentId = "0"
                        }
                    }

                    $objects
                }

                Mock -CommandName Invoke-BurpSuiteDeployment -MockWith {
                    $objects = @()

                    $objects += [PSCustomObject]@{
                        ResourceId        = 'BurpSuite/Folders/Example.com'
                        Properties        = @{
                            parentId = "0"
                        }
                        ProvisioningState = [ProvisioningState]::Succeeded
                    }

                    $objects += [PSCustomObject]@{
                        ResourceId        = 'BurpSuite/Folders/Example2.com'
                        Properties        = @{
                            parentId = "0"
                        }
                        ProvisioningState = [ProvisioningState]::Error
                    }

                    $objects
                }

                # act
                { Invoke-BurpSuiteDeploy -TemplateFile $testTemplateFile -Uri $testUri  -APIkey $testKey } | Should -Throw
            }
        }
    }
}
