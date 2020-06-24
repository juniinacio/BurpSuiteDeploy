---
external help file: BurpSuiteDeploy-help.xml
Module Name: BurpSuiteDeploy
online version: https://github.com/juniinacio/BurpSuiteDeploy
schema: 2.0.0
---

# Invoke-BurpSuiteDeployment

## SYNOPSIS
Invokes one or more deployments.

## SYNTAX

```
Invoke-BurpSuiteDeployment [-Deployment] <PSObject> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Invokes one or more deployments.

## EXAMPLES

### Example 1
```powershell
PS C:\> (Get-BurpSuiteDeployment -TemplateFile C:\templates\BurpSuite.json) | Invoke-BurpSuiteDeployment
```

This example show how to execute one or more deployments.

## PARAMETERS

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Deployment
Specify a deployment object, pipe the output from `Get-BurpSuiteDeployment` to this parameter.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[https://github.com/juniinacio/BurpSuiteDeploy](https://github.com/juniinacio/BurpSuiteDeploy)

