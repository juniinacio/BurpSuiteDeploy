InModuleScope $env:BHProjectName {
    Describe "_createTempFile" {
        Context "Write temp files" {
            It "should call New-TemporaryFile" {
                # arrange
                $testContent = "HelloWorld!"
                $testPath = "TestDrive:\{0}.json" -f [Guid]::NewGuid()
                $testPath = New-Item -Path $testPath -ItemType File

                Mock -CommandName New-TemporaryFile -MockWith {
                    $testPath
                } -Verifiable

                Mock -CommandName Out-File

                # act
                $assert = _createTempFile -InputObject $testContent

                # assert
                Should -Invoke -CommandName Out-File -ParameterFilter {
                    $NoNewline.IsPresent -eq $true `
                    -and $InputObject -eq $testContent `
                    -and $FilePath -eq $testPath
                }

                $assert.FullName | Should -Be $testPath.FullName
            }
        }
    }

    Describe "_convertToHashtable" {
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
                $assert = _convertToHashtable -InputObject $pso

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
