InModuleScope $env:BHProjectName {
    Describe "Get-BurpSuiteResource" {
        Context "Deployment Objects" {
            BeforeAll {
                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should return deployments" {
                # arrange
                $testTemplateFile = Join-Path -Path $testArtifacts -ChildPath 'AllResourceTypes.json'

                # act
                $deployments = Get-BurpSuiteResource -TemplateFile $testTemplateFile

                # assert
                $deployments.Count | Should -Be 4
            }
        }

        Context "Topological Sorting" {
            BeforeAll {
                $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath '..\artifacts'
                $testUri = "https://burpsuite.example.com"
                $testKey = "ItDoesNotMatter"
            }

            It "should sort deployments based on dependencies" {
                # arrange
                $testTemplateFile = Join-Path -Path $testArtifacts -ChildPath 'ResourcesWithDependencies.json'
                $testScanConfiguration = Get-Content -Path (Join-Path -Path $testArtifacts -ChildPath 'ScanConfigurationDeploymentType.json') | ConvertFrom-Json
                $testFolder = Get-Content -Path (Join-Path -Path $testArtifacts -ChildPath 'FolderDeploymentType.json') | ConvertFrom-Json
                $testSite = Get-Content -Path (Join-Path -Path $testArtifacts -ChildPath 'SiteDeploymentType.json') | ConvertFrom-Json
                $testFolderSite = Get-Content -Path (Join-Path -Path $testArtifacts -ChildPath 'FolderSiteDeploymentType.json') | ConvertFrom-Json

                # act
                $deployments = Get-BurpSuiteResource -TemplateFile $testTemplateFile

                # assert
                $deployments.Count | Should -Be 4

                # A DAG can have multiple solutions, so arrange accordingly
                if ($deployments[0].ResourceType -eq $testScanConfiguration.ResourceType) {
                    $deployments[0].ResourceId | Should -Be $testScanConfiguration.ResourceId
                    $deployments[0].ResourceType | Should -Be $testScanConfiguration.ResourceType
                    $deployments[0].Name | Should -Be $testScanConfiguration.Name

                    $deployments[1].ResourceId | Should -Be $testFolder.ResourceId
                    $deployments[1].ResourceType | Should -Be $testFolder.ResourceType
                    $deployments[1].Name | Should -Be $testFolder.Name
                } else {
                    $deployments[0].ResourceId | Should -Be $testFolder.ResourceId
                    $deployments[0].ResourceType | Should -Be $testFolder.ResourceType
                    $deployments[0].Name | Should -Be $testFolder.Name

                    $deployments[1].ResourceId | Should -Be $testScanConfiguration.ResourceId
                    $deployments[1].ResourceType | Should -Be $testScanConfiguration.ResourceType
                    $deployments[1].Name | Should -Be $testScanConfiguration.Name
                }

                if ($deployments[2].ResourceType -eq $testSite.ResourceType) {
                    $deployments[2].ResourceId | Should -Be $testSite.ResourceId
                    $deployments[2].ResourceType | Should -Be $testSite.ResourceType
                    $deployments[2].Name | Should -Be $testSite.Name

                    $deployments[3].ResourceId | Should -Be $testFolderSite.ResourceId
                    $deployments[3].ResourceType | Should -Be $testFolderSite.ResourceType
                    $deployments[3].Name | Should -Be $testFolderSite.Name
                } else {
                    $deployments[2].ResourceId | Should -Be $testFolderSite.ResourceId
                    $deployments[2].ResourceType | Should -Be $testFolderSite.ResourceType
                    $deployments[2].Name | Should -Be $testFolderSite.Name

                    $deployments[3].ResourceId | Should -Be $testSite.ResourceId
                    $deployments[3].ResourceType | Should -Be $testSite.ResourceType
                    $deployments[3].Name | Should -Be $testSite.Name
                }
            }
        }
    }
}
