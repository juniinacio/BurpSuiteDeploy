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
    }
}
