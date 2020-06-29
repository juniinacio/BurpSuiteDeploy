---
external help file: BurpSuiteDeploy-help.xml
Module Name: BurpSuiteDeploy
online version: https://github.com/juniinacio/BurpSuiteDeploy
schema: 2.0.0
---

# Get-BurpSuiteDeployment

## SYNOPSIS
Reads all deployments from a JSON template file.

## SYNTAX

```
Get-BurpSuiteDeployment [-TemplateFile] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Reads all deployments from a JSON template file.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-BurpSuiteDeployment -TemplateFile C:\templates\BurpSuite.json
```

This example show how to get all deployment objects out of a file.

## PARAMETERS

### -TemplateFile
Specify the path to your BurpSuite JSON file.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[https://github.com/juniinacio/BurpSuiteDeploy](https://github.com/juniinacio/BurpSuiteDeploy)

