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

    Context 'Resources' {
        It 'should deploy resources' {
            # Arrange

            # Act
            $assert = Invoke-BurpSuiteDeploy -TemplateFile $testArtifacts\AllResourceTypes.json -Uri $BURPSUITE_URL  -APIkey $BURPSUITE_APIKEY

            # Assert
            @($assert).ProvisioningState -contains 'Error' | Should -Be $false
        }
    }

    AfterAll {
        Connect-BurpSuite -Uri $BURPSUITE_URL  -APIkey $BURPSUITE_APIKEY

        $siteTree = Get-BurpSuiteSiteTree

        Get-BurpSuiteScan | Where-Object { $_.status -in @("running", "queued") } | Stop-BurpSuiteScan -Confirm:$false

        $siteTree.folders | Where-Object { $_.Name -eq "Example" } | Remove-BurpSuiteFolder -Confirm:$false
        $siteTree.sites | Where-Object { $_.Name -eq "www.example.com" } | Remove-BurpSuiteSite -Confirm:$false

        Get-BurpSuiteScheduleItem -Fields id, schedule, site | Where-Object { $_.site.name -like "*.example.com" } | Remove-BurpSuiteScheduleItem -Confirm:$false

        Start-Sleep -Seconds 5

        try {
            Get-BurpSuiteScanConfiguration | Where-Object { $_.name -eq "Example - Large Scan Configuration" } | Remove-BurpSuiteScanConfiguration -Confirm:$false -ErrorAction SilentlyContinue
        } catch {}
    }
}
