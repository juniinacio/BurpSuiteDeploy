---
external help file: BurpSuiteDeploy-help.xml
Module Name: BurpSuiteDeploy
online version: https://github.com/juniinacio/BurpSuiteDeploy
schema: 2.0.0
---

# Invoke-BurpSuiteDeploy

## SYNOPSIS
Applies your configuration on BurpSuite.

## SYNTAX

```
Invoke-BurpSuiteDeploy [-TemplateFile] <String[]> [-Uri] <String> [-APIKey] <String> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Applies your configuration on BurpSuite.

## EXAMPLES

### Example 1
```powershell
PS C:\> Invoke-BurpSuiteDeploy -TemplateFile C:\templates\BurpSuite.json -Uri https://burpsuite.example.com  -APIkey 'MyKey'
```

This example shows how to apply a configuration.

## PARAMETERS

### -APIKey
Specify the API key for connecting to your BurpSuite instance.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

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

### -TemplateFile
Specify the path to your BurpSuite configuration template.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Uri
Specify the URI for connecting to your BurpSuite instance.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

