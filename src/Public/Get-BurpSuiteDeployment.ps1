function Get-BurpSuiteDeployment {
    [CmdletBinding(HelpUri = 'https://github.com/juniinacio/BurpSuiteDeploy', ConfirmImpact = 'Low')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf -ErrorAction Stop })]
        [string[]] $TemplateFile
    )

    begin {
    }

    process {
        try {
            $resources = foreach($path in $TemplateFile) {
                $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)

                $template = ConvertFrom-Json -InputObject (Get-Content -Path $path -Raw | Out-String)

                foreach($resource in $template.resources) {
                    [PSCustomObject]@{
                        ResourceId = @($resource.type.TrimEnd("/"), $resource.name.TrimStart("/")) -join "/"
                        ResourceType = $resource.type.TrimEnd("/")
                        Name = $resource.name
                        Properties = $resource.Properties
                    }
                }
            }

            if (-not $resources) {
                throw "No resources processed. Something went wrong."
            }

            $resources
        } catch {
            throw
        }
    }

    end {
    }
}
