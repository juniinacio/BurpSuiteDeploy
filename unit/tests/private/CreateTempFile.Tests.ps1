InModuleScope $env:BHProjectName {
    Describe "CreateTempFile" {
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
                $assert = CreateTempFile -InputObject $testContent

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
}
