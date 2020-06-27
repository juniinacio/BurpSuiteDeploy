InModuleScope $env:BHProjectName {
    Describe "Get-BurpSuiteDeployment" {
        Context "Deployment objects" {
            BeforeAll {
                $testTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts\AllResourceTypes.json'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should return deployments" {
                # arrange

                # act
                $deployments = Get-BurpSuiteDeployment -TemplateFile $testTemplateFile

                # assert
                $deployments.Count | Should -Be 3

                $deployments[0].ResourceId | Should -Be 'BurpSuite/Folders/Example.com'
                $deployments[0].ResourceType | Should -Be 'BurpSuite/Folders'
                $deployments[0].Name | Should -Be 'Example.com'
                $deployments[0].Properties | Should -Not -BeNullOrEmpty
            }
        }

        Context "Topological sorting" {
            BeforeAll {
                $testTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts\ResourcesWithDependencies.json'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should sort deployments based on dependencies" {
                # arrange

                # act
                $deployments = Get-BurpSuiteDeployment -TemplateFile $testTemplateFile

                # assert
                $deployments.Count | Should -Be 4

                # A DAG can have multiple solutions, so arrange accordingly
                if ($deployments[0].ResourceType -eq "BurpSuite/ScanConfigurations") {
                    $deployments[0].ResourceId | Should -Be 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration'
                    $deployments[0].ResourceType | Should -Be 'BurpSuite/ScanConfigurations'
                    $deployments[0].Name | Should -Be 'Example - Large Scan Configuration'

                    $deployments[1].ResourceId | Should -Be 'BurpSuite/Folders/Example.com'
                    $deployments[1].ResourceType | Should -Be 'BurpSuite/Folders'
                    $deployments[1].Name | Should -Be 'Example.com'
                } else {
                    $deployments[0].ResourceId | Should -Be 'BurpSuite/Folders/Example.com'
                    $deployments[0].ResourceType | Should -Be 'BurpSuite/Folders'
                    $deployments[0].Name | Should -Be 'Example.com'

                    $deployments[1].ResourceId | Should -Be 'BurpSuite/ScanConfigurations/Example - Large Scan Configuration'
                    $deployments[1].ResourceType | Should -Be 'BurpSuite/ScanConfigurations'
                    $deployments[1].Name | Should -Be 'Example - Large Scan Configuration'
                }

                if ($deployments[2].ResourceType -eq "BurpSuite/Sites") {
                    $deployments[2].ResourceId | Should -Be 'BurpSuite/Sites/www.example.com'
                    $deployments[2].ResourceType | Should -Be 'BurpSuite/Sites'
                    $deployments[2].Name | Should -Be 'www.example.com'

                    $deployments[3].ResourceId | Should -Be 'BurpSuite/Folders/Example.com/Sites/www.example.com'
                    $deployments[3].ResourceType | Should -Be 'BurpSuite/Folders/Sites'
                    $deployments[3].Name | Should -Be 'www.example.com'
                } else {
                    $deployments[2].ResourceId | Should -Be 'BurpSuite/Folders/Example.com/Sites/www.example.com'
                    $deployments[2].ResourceType | Should -Be 'BurpSuite/Folders/Sites'
                    $deployments[2].Name | Should -Be 'www.example.com'

                    $deployments[3].ResourceId | Should -Be 'BurpSuite/Sites/www.example.com'
                    $deployments[3].ResourceType | Should -Be 'BurpSuite/Sites'
                    $deployments[3].Name | Should -Be 'www.example.com'
                }
            }
        }
    }
}
