function Get-BurpSuiteResource {
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
                        DependsOn = $resource.dependsOn
                    }

                    if ($null -ne (_tryGetProperty -InputObject $resource -PropertyName 'resources')) {
                        foreach($childResource in $resource.resources) {
                            [PSCustomObject]@{
                                ResourceId = @($resource.type.TrimEnd("/"), (($childResource.name.TrimStart("/")) -split "/")[0], $childResource.type.TrimEnd("/"), (($childResource.name.TrimStart("/")) -split "/")[-1]) -join "/"
                                ResourceType = @($resource.type.TrimEnd("/"), $childResource.type.TrimStart("/")) -join "/"
                                Name = (($childResource.name.TrimStart("/")) -split "/")[-1]
                                Properties = $childResource.Properties
                                DependsOn = $childResource.dependsOn
                            }
                        }
                    }
                }
            }

            if (-not $resources) {
                throw "No resources processed. Something went wrong."
            }

            _sortDeployment -Resources $resources
        } catch {
            throw
        }
    }

    end {
    }
}
