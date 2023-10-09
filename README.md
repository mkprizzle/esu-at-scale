# Azure Arc Enabled Windows 2012 ESU
This is a repository that hosts a forked and updated version of a sample set of scripted operations (Created by Adam Turner) using the Resource Manager API (provided by management.azure.com) to perform the following operations:
+ Create an ESU license (activated or deactivated)
+ Update an ESU license (activate or deactivate)
+ Link ESU license to an Arc-Enabled Windows 2012 Machine or specify an array of comma-separated machine names, or provide a CSV with a MachineName column, or work within an entire Resource Group.
+ Delete linked ESU license from an Arc-Enabled Windows 2012 Machine, an array of machines, or provide a CSV, or within an entire Resource Goup.
+ Deactivate an ESU license
+ Delete an ESU license

This updated script is parameterized for a larger set of idempotent operations and will help manage ESUs and their assignments at scale while the Product Groups are developing official SDK-based automation through CLI/PowerShell.

You can use a Service Principal or your own credential to perform the operations in this script.  Note that your service principal should have appropriate permissions to deploy ESU licenses and assign licenses to Arc Enabled Machines.  The built-in role permission required to create and assign licenses to Arc-enabled machines is either "Contributor" or "Owner" roles.  The specific permission is 'Microsoft.HybridCompute/licenses/write'

It is important to understand the underlying licensing requirements for ESU.  If you use this you are responsible for the licensing count and ensuring that the number of cores applied meet all licensing requirements for ESU delivery.  At a minimum please ensure that you read through https://learn.microsoft.com/en-us/azure/azure-arc/servers/license-extended-security-updates - and if this is unclear and you are still uncertain, please work with your local Microsoft licensing expert to ensure that you are not breaking licensing compliance.

# Pre-requisites:
Tested on PowerShell 7.3.7 with PowerShell Az module 10.3.0 - running on prior versions will generate errors.
You will need the Az.ConnectedMachine PowerShell module which can be installed by running
```powershell
Install-Module az.connectedmachine -scope currentuser
```

# Please note:
This information is being provided as-is with the terms of the MIT license, with no warranty/guarantee or support.  It is free to use - and for demonstration purposes only.  The process of hardening this into your needs is a task I leave to you.

# Additional note:
Please see the help section in the script file for additional information about how to run the script and the different parameters required for different operations.  This was built to help streamline all aspects of ESU management automation into one script, so there are many parameters that are required together.
