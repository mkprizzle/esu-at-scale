# Azure Arc Enabled Windows 2012 ESU
This is a repository that hosts a sample run through of the Resource Manager API (provided by management.azure.com) to perform the following operations:
+ Create an ESU license (deactivated)
+ Update an ESU license (activated)
+ Link ESU license to a Machine
+ Delete linked ESU license from a Machine
+ Deactivate an ESU license
+ Delete an ESU license

In accordance with best practices I used a service principal to log in and perform these operations.  Note that your service principal should have appropriate permissions to deploy ESU licenses and assign licenses to Arc Enabled Machines.  The built-in RBAC permission you're looking for is "Azure Connected Machine Resource Administrator".  You could potentially use the same service principal that you used to onboard your machines to Arc.  Up to you on that note - if you'd like to use a separate identity due to security constraints/concerns that would be totally valid.

I cannot stress enough how important it is that the underpinning licensing requirements for ESU are understood.  If you use this you are responsible for the licensing count and ensuring that the number of cores applied meet all licensing requirements for ESU delivery.  At a minimum please ensure that you read through https://learn.microsoft.com/en-us/azure/azure-arc/servers/license-extended-security-updates - and if this is unclear and you are still uncertain, please work with your local Microsoft licensing expert to ensure that you are not breaking licensing compliance.

# Please note:
This information is being provided as-is with the terms of the MIT license, with no warranty/guarantee or support.  It is free to use - and for demonstration purposes only.  The process of hardening this into your needs is a task I leave to you.

# Additional note:
This shows a mechanism to use the Resource Manager API to accomplish this task.  This will likely be simpler when PowerShell updates to the official Az module and when the CLI updates the same.  Resource Manager APIs are available now.
