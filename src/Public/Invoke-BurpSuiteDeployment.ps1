function Invoke-BurpSuiteDeployment {
    [CmdletBinding(SupportsShouldProcess = $true,
        HelpUri = 'https://github.com/juniinacio/BurpSuiteDeploy',
        ConfirmImpact = 'Medium')]
    Param (
        [parameter(ValueFromPipeline = $True,
            Mandatory = $True)]
        # [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'BurpSuite.Deployment' })]
        [psobject]$Deployment
    )

    begin {
        $siteTree = Get-BurpSuiteSiteTree
        $scanConfigurations = Get-BurpSuiteScanConfiguration
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Deploy", $Deployment.ResourceId)) {
                switch ($Deployment.ResourceType) {
                    'BurpSuite/Folders' {
                        $resource = $siteTree.folders | Where-Object { $_.parent_id -eq 0 -and $_.name -eq $Deployment.Name }
                        if ($null -eq $resource) {
                            $resource = New-BurpSuiteFolder -ParentId 0 -Name $Deployment.Name
                        }
                    }
                    'BurpSuite/Sites' {
                        # $commandArgs = ConvertToHashtable -InputObject $Deployment.Properties
                        # $resource = New-BurpSuiteSite -Name $Deployment.Name @commandArgs
                        $resource = $siteTree.sites | Where-Object { $_.parent_id -eq 0 -and $_.name -eq $Deployment.Name }
                        if ($null -eq $resource) {
                            $resource = New-BurpSuiteSite -Name $Deployment.Name `
                                -ParentId 0 `
                                -IncludedUrls $Deployment.Properties.scope.includedUrls `
                                -ExcludedUrls $Deployment.Properties.scope.excludedUrls `
                                -ScanConfigurationIds $Deployment.Properties.scanConfigurationIds `
                                # -EmailRecipients $Deployment.Properties.emailRecipients.email
                        }
                    }
                    'BurpSuite/ScanConfigurations' {
                        $resource = $scanConfigurations | Where-Object { $_.name -eq $Deployment.Name }
                        if ($null -eq $resource) {
                            $tempFile = CreateTempFile -InputObject $Deployment.Properties.scanConfigurationFragmentJson
                            $resource = New-BurpSuiteScanConfiguration -Name $Deployment.Name -FilePath $tempFile.FullName
                        }
                    }
                    default {
                        throw "Unknown resource type."
                    }
                }

                [PSCustomObject]@{
                    Id                = $resource.Id
                    ResourceId        = $Deployment.ResourceId
                    ProvisioningState = [ProvisioningState]::Succeeded
                }
            }
        } catch {
            throw
        }
    }

    end {
    }
}
