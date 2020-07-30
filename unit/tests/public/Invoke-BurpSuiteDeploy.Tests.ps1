InModuleScope $env:BHProjectName {
    Describe "Invoke-BurpSuiteDeploy" {
        Context "Authenticating to BurpSuite" {
            BeforeAll {
                function Connect-BurpSuite ($Uri, $APIKey) { }
                function Disconnect-BurpSuite { }

                Mock -CommandName Get-BurpSuiteResource -MockWith {}
                Mock -CommandName Invoke-BurpSuiteResource -MockWith {
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
                Mock -CommandName Invoke-BurpSuiteResource -MockWith {
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

                Mock -CommandName Get-BurpSuiteResource -MockWith {}

                Mock -CommandName Invoke-BurpSuiteResource -MockWith {
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

            It "should call Get-BurpSuiteResource" {
                # arrange
                Mock -CommandName Get-BurpSuiteResource

                # act
                Invoke-BurpSuiteDeploy -TemplateFile $testTemplateFile -Uri $testUri  -APIkey $testKey

                # assert
                Should -Invoke -CommandName Get-BurpSuiteResource -ParameterFilter {
                    $TemplateFile -eq $testTemplateFile
                }
            }
        }

        Context "Deploying resources" {
            BeforeAll {
                function Connect-BurpSuite ($Uri, $APIKey) { }
                function Disconnect-BurpSuite { }

                Mock -CommandName Get-BurpSuiteResource -MockWith {}

                $testTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts\AllResourceTypes.json'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should call Invoke-BurpSuiteResource" {
                # arrange
                Mock -CommandName Get-BurpSuiteResource -MockWith {
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
                Mock -CommandName Invoke-BurpSuiteResource -MockWith {
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
                Should -Invoke Invoke-BurpSuiteResource -ParameterFilter {
                    $InputObject.ResourceId -eq 'BurpSuite/Folders/Example.com' `
                        -and $InputObject.Properties.ParentId -eq 0
                }

                Should -Invoke Invoke-BurpSuiteResource -ParameterFilter {
                    $InputObject.ResourceId -eq 'BurpSuite/Sites/root.example.com' `
                        -and $InputObject.Properties.ParentId -eq 0
                }

                Should -Invoke Invoke-BurpSuiteResource -ParameterFilter {
                    $InputObject.ResourceId -eq 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration' `
                        -and $InputObject.Properties.ParentId -eq 0
                }
            }

            It "should return deployment objects" {
                # arrange
                Mock -CommandName Get-BurpSuiteResource -MockWith {
                    $objects = @()

                    $objects += [PSCustomObject]@{
                        ResourceId = 'BurpSuite/Folders/Example.com'
                        Properties = @{
                            parentId = "0"
                        }
                    }

                    $objects
                }

                Mock -CommandName Invoke-BurpSuiteResource -MockWith {
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
                Mock -CommandName Get-BurpSuiteResource -MockWith {
                    $objects = @()

                    $objects += [PSCustomObject]@{
                        ResourceId = 'BurpSuite/Folders/Example.com'
                        Properties = @{
                            parentId = "0"
                        }
                    }

                    $objects
                }

                Mock -CommandName Invoke-BurpSuiteResource -MockWith {
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
