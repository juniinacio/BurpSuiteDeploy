function Invoke-BurpSuiteDeploy {
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://github.com/juniinacio/BurpSuiteDeploy', ConfirmImpact = 'Medium')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf -ErrorAction Stop })]
        [string[]] $TemplateFile,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $APIKey
    )

    begin {
        try {
            Connect-BurpSuite -Uri $Uri -APIKey $APIKey
        } catch {
            throw
        }
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Deploy", $TemplateFile)) {

                $deployments = Get-BurpSuiteResource -TemplateFile $TemplateFile

                $provisioningResults = $deployments | New-BurpSuiteResource -Confirm:$false

                if (@($provisioningResults).ProvisioningState -contains [ProvisioningState]::Error) {
                    Write-Error -Message "Provisioning of one or more resources completed with errors."
                }

                $provisioningResults
            }
        } catch {
            throw
        }
    }

    end {
        try {
            Disconnect-BurpSuite
        } catch {
            throw
        }
    }
}
