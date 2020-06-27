InModuleScope $env:BHProjectName {
    Describe "_testIsExpression" {
        Context "Testing for valid expressions" {
            It "should return false" {
                # arrange
                $testString = "foo"

                # act
                $assert = _testIsExpression -InputString $testString

                # assert
                $assert | Should -Be $false
            }

            It "should return true" {
                # arrange
                $testString = "[variables('foo')]"

                # act
                $assert = _testIsExpression -InputString $testString

                # assert
                $assert | Should -Be $true
            }
        }
    }

    Describe "_resolveExpression" {
        Context "Resole template expressions" {
            It "should resolve variables expressions" {
                # arrange
                $variables = @{foo = 'bar' }
                $testString = "[variables('foo')]"

                # act
                $assert = _resolveExpression -InputString $testString -variables $variables

                # assert
                $assert | Should -Be 'bar'
            }

            It "should resolve resourceId expressions" {
                # arrange
                $resources = @()
                $resources += [PSCustomObject]@{
                    Id   = 'BurpSuite/Sites/www.example.com'
                    Name = 'www.example.com'
                }
                $testString = "[resourceId('BurpSuite/Sites', 'www.example.com')]"

                # act
                $assert = _resolveExpression -InputString $testString -resources $resources

                # assert
                $assert | Should -Be 'BurpSuite/Sites/www.example.com'
            }

            It "should resolve reference expressions" {
                # arrange
                $resources = @()
                $resources += [PSCustomObject]@{
                    Id   = 'BurpSuite/Sites/www.example.com'
                    Name = 'www.example.com'
                }
                $testString = "[(reference('BurpSuite/Sites/www.example.com')).Name]"

                # act
                $assert = _resolveExpression -InputString $testString -resources $resources

                # assert
                $assert | Should -Be 'www.example.com'
            }

            It "should resolve concat expressions" {
                # arrange
                $testString = "[concat('BurpSuite/Sites', '/', 'www.example.com')]"

                # act
                $assert = _resolveExpression -InputString $testString -resources $resources

                # assert
                $assert | Should -Be 'BurpSuite/Sites/www.example.com'
            }

            It "should resolve complex resourceId expressions" {
                # arrange
                $resources = @()
                $resources += [PSCustomObject]@{
                    Id   = 'BurpSuite/Sites/www.example.com'
                    Name = 'www.example.com'
                }
                $testString = "[resourceId('BurpSuite/Sites', (concat('www', '.', 'example', '.', 'com')))]"

                # act
                $assert = _resolveExpression -InputString $testString -resources $resources

                # assert
                $assert | Should -Be 'BurpSuite/Sites/www.example.com'
            }

            It "should resolve complex reference expressions" {
                # arrange
                $resources = @()
                $resources += [PSCustomObject]@{
                    Id   = 'BurpSuite/Sites/www.example.com'
                    Name = 'www.example.com'
                }
                $testString = "[(reference((resourceId('BurpSuite/Sites', (concat('www', '.', 'example', '.', 'com')))))).Name]"

                # act
                $assert = _resolveExpression -InputString $testString -resources $resources

                # assert
                $assert | Should -Be 'www.example.com'
            }

            It "should not resolve certain expressions" {
                # arrange
                $testString = "[concat((Get-ChildItem))]"

                Mock -CommandName Invoke-Expression

                # act
                $assert = _resolveExpression -InputString $testString -resources $resources

                # assert
                Should -Invoke -CommandName Invoke-Expression -Times 0 -Scope It
            }
        }
    }
}
