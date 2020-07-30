---
external help file: BurpSuiteDeploy-help.xml
Module Name: BurpSuiteDeploy
online version: https://github.com/juniinacio/BurpSuiteDeploy
schema: 2.0.0
---

# Invoke-BurpSuiteResource

## SYNOPSIS
Invokes one or more deployments.

## SYNTAX

```
Invoke-BurpSuiteResource [-InputObject] <Object> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates one or more resources.

## EXAMPLES

### Example 1
```powershell
PS C:\> (Get-BurpSuiteResource -TemplateFile C:\templates\BurpSuite.json) | Invoke-BurpSuiteResource
```

This example shows how to create one or more resources.

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

### -InputObject
Specifies a template resource to create.

```yaml
Type: Object
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

