# BurpSuiteDeploy

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/juniinacio/BurpSuiteDeploy/blob/master/LICENSE)
[![Documentation - BurpSuiteDeploy](https://img.shields.io/badge/Documentation-BurpSuiteDeploy-blue.svg)](https://github.com/juniinacio/BurpSuiteDeploy/blob/master/README.md)
[![PowerShell Gallery - BurpSuiteDeploy](https://img.shields.io/badge/PowerShell%20Gallery-BurpSuiteDeploy-blue.svg)](https://www.powershellgallery.com/packages/BurpSuiteDeploy)
[![Minimum Supported PowerShell Version](https://img.shields.io/badge/PowerShell-5.1-blue.svg)](https://github.com/PowerShell/PowerShell)

## Introduction

PowerShell module for configuring BurpSuite using JSON configuration files.

Documentation of the cmdlets can be found in the [docs README](https://github.com/juniinacio/BurpSuiteDeploy/blob/master/docs/en-US/about_BurpSuiteDeploy.help.md) or using `Get-Help BurpSuiteDeploy` once the module is installed.

## Requirements

- Windows PowerShell 5.1 or newer.
- PowerShell Core.

## Installation

Install this module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/BurpSuiteDeploy).

```PowerShell
Install-Module -Name BurpSuiteDeploy
```

## Change Log

[Change Log](CHANGELOG.md)

## Pipeline Status

You can review the status of every BurpSuite pipeline below.

|         Pipeline                    |             Status           |
|-------------------------------------|------------------------------|
| Production                          | [![Build Status](https://dev.azure.com/juniinacio/BurpSuite/_apis/build/status/BurpSuiteDeploy?branchName=master)](https://dev.azure.com/juniinacio/BurpSuite/_build/latest?definitionId=14&branchName=master) |

The build for BurpSuiteDeploy is run on Linux and Windows to ensure there are no casing or other platform specific issues with the code. On each platform unit tests are run to ensure the code runs on all platforms and without issues. During pull request builds the module is also installed both on Windows and Linux and tested using integration tests against BurpSuite Enterprise before changes are pushed to the master branch.

## Building Module

### How to build locally

To run build the script `build.ps1`. The script has the following parameters:

* `-Task '<Task Name>'`: Specifies the task you wish to run, default is Test, see [build.ps1](build.ps1) or alternatively run `.\build.ps1 -Help`.
* `-Bootstrap`: By default the build will not install dependencies unless this switch is used.
* `-Help`: Lists al tasks available for the building.

Below are some examples on how to build the module locally. It is expected that your working directory is at the root of the repository.

Builds the module, runs unit tests and also builds the help.
```PowerShell
.\build.ps1
```

Builds the module, installs needed dependencies, runs unit tests and also builds the help.
```PowerShell
.\build.ps1 -Bootstrap
```

## Using Module

### Getting started with BurpSuiteDeploy

Before you can start using the `Invoke-BurpSuiteDeploy` command for deployments, you need to create a JSON configuration file specifying the resources you wish to be created. The structure of the JSON configuration files resembles the Azure Resource Manager (ARM) structure.

BurpSuiteDeploy supports creating the following resources:

|  BurpSuite Resource  |  Resource Type  |  Description |
|----------------------|-----------------|--------------|
|  Site                | BurpSuite/Sites | This resource type creates sites. |
|  Folder              | BurpSuite/Folders | This resource type creates folders. |
|  Site*               | BurpSuite/Folders/Sites | This resource type creates sites inside folders. |
|  Scan Configuration  | BurpSuite/ScanConfigurations | This resource type creates scan configurations. |
|  Schedule Item       | BurpSuite/ScheduleItems | This resource type creates schedule items. |

For example JSON templates see [examples](examples) or [unit tests artifacts](unit\tests\artifacts) (as soon as I get more time on my hands I will write a proper documentation about this module, everyone is also welcome to contribute with BurpSuiteDeploy).

To start deploying your configuration templates you will first need to create a API key in the BurpSuite Enterprise UI. After getting the API key you can trigger a deployment using the `Invoke-BurpSuiteDeploy` command.

To do a template deployment use the following command:

```powershell
Invoke-BurpSuiteDeploy -TemplateFile C:\templates\burpsuiteDeploy.json -APIKey 'd0D99S3Strkcdd8oALICjmPtwJuLbFtKX' -Uri "https://burpsuite.example.org"
```

For more example see the examples available throughout the module.

## Contributors

[Guidelines](.github/CONTRIBUTING.md)

## Maintainers

- [Juni Inacio](https://github.com/juniinacio) - [@Jinac81](https://twitter.com/Jinac81)

## License

This project is [licensed under the MIT License](LICENSE).
