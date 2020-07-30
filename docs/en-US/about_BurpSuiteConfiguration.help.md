# BurpSuiteDeploy

## about_BurpSuiteDeploy

# SHORT DESCRIPTION

BurpSuiteDeploy is a PowerShell module for configuring BurpSuite Enterprise using JSON configuration files.

BurpSuite supports Windows PowerShell 5.1 and greater.

# LONG DESCRIPTION
BurpSuiteDeploy is a PowerShell module for configuring BurpSuite Enterprise using JSON configuration files. By using this module you can configure your BurpSuite Enterprise server using JSON file. In each JSON template file you can specify one or more resources that describe what should be created in BurpSuite.

BurpSuiteDeploy borrows a lot of concepts and features from Azure Resource Manager templates.

Using BurpSuiteDeploy you will be able to create sites, folders, scan configurations, schedule items and more in the future.

# EXAMPLES

## Example 1

```powershell
PS C:\> Invoke-BurpSuiteDeploy -TemplateFile C:\templates\BurpSuite.json -Uri https://burpsuite.example.com  -APIkey 'MyKey'
```

This example shows how to deploy a single template.

# NOTE

None.

# TROUBLESHOOTING NOTE

None.

# SEE ALSO

about_BurpSuiteDeployResources

about_BurpSuiteDeployFunctions

## LINK

https://github.com/juniinacio/BurpSuiteDeploy

