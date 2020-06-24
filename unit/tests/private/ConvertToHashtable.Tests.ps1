InModuleScope $env:BHProjectName {
    Describe "ConvertToHashtable" {
        Context "Convert objects" {
            It "should convert objects to hashtable" {
                # arrange
                $pso = [PSCustomObject]@{
                    ParentId = 0
                    IncludedUrls = @(
                        "https://www.example.com"
                    )
                    ExcludedUrls = @(
                        "https://www.example.com/login"
                    )
                }

                # act
                $assert = ConvertToHashtable -InputObject $pso

                # assert
                $assert.GetType().Name | Should -Be 'Hashtable'
                {$assert.ContainsKey('ParentId')} | Should -Not -Throw
                $assert.ParentId | Should -Be 0
                ($assert.IncludedUrls -contains "https://www.example.com") | Should -Not -BeNullOrEmpty
                ($assert.ExcludedUrls -contains "https://www.example.com/login") | Should -Not -BeNullOrEmpty
            }
        }
    }
}
