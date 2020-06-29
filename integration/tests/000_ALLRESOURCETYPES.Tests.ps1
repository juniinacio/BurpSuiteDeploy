Set-StrictMode -Version Latest

##############################################################
#     THESE TEST ARE DESTRUCTIVE. USE A CLEAN BURPSUITE.     #
##############################################################
# Before running these tests you must set the following      #
# Environment variables.                                     #
# $env:BURPSUITE_APIKEY = BurpSuite Enterprise API key       #
# $env:BURPSUITE_APIVERSION = v1                             #
# $env:BURPSUITE_URL = Url to BurpSuite Enterprise           #
##############################################################
#     THESE TEST ARE DESTRUCTIVE. USE A CLEAN BURPSUITE.     #
##############################################################

Describe 'Invoke-BurpSuiteDeploy' -Tag 'CD' {
    BeforeAll {
        $BURPSUITE_APIKEY = $env:BURPSUITE_APIKEY
        $BURPSUITE_APIVERSION = $env:BURPSUITE_APIVERSION
        $BURPSUITE_URL = $env:BURPSUITE_URL

        $testArtifacts = Join-Path -Path $PSScriptRoot -ChildPath 'artifacts'
    }

    Context 'Parent resources' {
        It 'should deploy resources' {
            # Arrange

            # Act
            { Invoke-BurpSuiteDeploy -TemplateFile $testArtifacts\AllResourceTypes.json -Uri $BURPSUITE_URL  -APIkey $BURPSUITE_APIKEY } | Should -Not -Throw

            # Assert
        }
    }
}
