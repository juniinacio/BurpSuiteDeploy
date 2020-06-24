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

Import-Module "D:\git\BurpSuite\.out\BurpSuite\1.0.0\BurpSuite.psd1" -Force
Import-Module "D:\git\BurpSuiteDeploy\.out\BurpSuiteDeploy\0.1.0\BurpSuiteDeploy.psd1" -Force

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
            $assert = Invoke-BurpSuiteDeploy -TemplateFile $testArtifacts\AllResourceTypes.json -Uri $BURPSUITE_URL  -APIkey $BURPSUITE_APIKEY

            # Assert
        }
    }
}
