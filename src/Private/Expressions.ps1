function _testIsExpression {
    [cmdletbinding()]
    param(
        [object] $InputString
    )

    $InputString -match '^\[.+\]$'
}

function _resolveExpression {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [cmdletbinding()]
    param(
        [object] $inputString,
        [hashtable] $variables,
        [object[]] $resources
    )

    if (-not (_testIsExpression -InputString $inputString)) {
        return $inputString
    }

    $safeCommands = @('variables', 'concat', 'resourceId', 'reference')

    $parsedString = (($inputString -replace '^\[', '') -replace '\]$', '')

    $expression = [scriptblock]::Create("return ($parsedString)")

    function variables([string]$name) { ($variables[$name]) }
    function concat([string[]]$arguments) { ($arguments -join '') }
    function resourceId([string[]]$segments) {
        $resourceId = (
            $segments |
            ForEach-Object {
                if (-not ([string]::IsNullOrEmpty($_))) {
                    $_.TrimEnd("/")
                }
            }
        ) -join '/'
        $resourceId
    }
    function reference([string]$resourceId) { $resources | Where-Object { $_.ResourceId -eq $resourceId } }

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($parsedString, [ref]$null, [ref]$null)

    $commandsAst = $ast.FindAll( {
            ($args[0] -is [System.Management.Automation.Language.CommandAst]) `
                -and $args[0].GetCommandName() -notin $safeCommands
        }, $true)

    if ($commandsAst.Count -eq 0) {
        & $expression
    }
}
