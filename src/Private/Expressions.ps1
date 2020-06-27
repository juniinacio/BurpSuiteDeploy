function _testIsExpression {
    [cmdletbinding()]
    param(
        [object] $InputString
    )

    $InputString -match "^\[[a-zA-z]+\(.+\)\]$"
}

function _resolveExpression {
    param(
        [object] $inputString,
        [hashtable] $variables,
        [object[]] $resources
    )

    $safeCommands = @('variables', 'concat', 'resourceId')

    $expression = [scriptblock]::Create("return ($inputString)")

    function variables([string]$name) { ($variables[$name]) }
    function concat([string[]]$arguments) { ($arguments -join '') }
    function resourceId([string[]]$resource) {
        $resourceId = ($resource |
            ForEach-Object {
                if ($null -ne $_) {
                    $_.TrimEnd("/")
                }
            }) -join '/'
        $resources | Where-Object { $_.Id -eq $resourceId }
    }

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($inputString, [ref]$null, [ref]$null)

    $commandsAst = $ast.FindAll( {
            ($args[0] -is [System.Management.Automation.Language.CommandAst]) `
                -and $args[0].GetCommandName() -notin $safeCommands
        }, $true)

    if ($commandsAst.Count -eq 0) {
        & $expression
    }
}
