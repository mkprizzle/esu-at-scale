# Azure Arc Enabled Windows 2012 ESU
This is a repository that hosts a modified forked repo version of a sample set of scripted operations (Created by Adam Turner, modified by Jordan Norby) using the Resource Manager API (provided by management.azure.com) to perform the following operations at scale and based on real-world usage:
+ Create ESU licenses in an activated state and link them to many servers
+ Create deactivated ESU licenses for staging while payment terms are being negotiated
+ Activate and link staged ESU licenses to Windows 2012 machines

This updated script is parameterized for a larger set of idempotent operations and will help manage ESUs and their assignments at scale while the Product Groups are developing official SDK-based automation through CLI/PowerShell.

This version of the script takes feedback from real-world usage and the need for a single-run script that can handle a few ESU onboarding use cases previous scripts have not addressed with pushbutton convenience:
+ Multiple subscription/resource group cross-deployment
+ Multiple core type and core count deployment in a single run for massive deployment scenarios
+ Differentiated Create Only vs Create, activate, and link run scenarios which can be useful for staging and attaching later if contracts are still in progress

What this does *not* do (yet)
+ One-to-many server links, which will link one license to multiple machines by groupings

This version of the script allows Service Principal only to enable cross-subscription ESU enablement if needed. Note that your service principal should have appropriate permissions to deploy ESU licenses and assign licenses to Arc Enabled Machines. The built-in role permission required to create and assign licenses to Arc-enabled machines is either "Contributor" or "Owner" roles. The least privilege method to run this script is to create a custom role based off of 'Azure Connected Machine Resource Administrator' with the added permissions:
+ Microsoft.HybridCompute/licenses/write
+ Microsoft.HybridCompute/machines/write
+ Microsoft.HybridCompute/machines/licenseProfiles/write

It is important to understand the underlying licensing requirements for ESU.  If you use this you are responsible for the licensing count and ensuring that the number of cores applied meet all licensing requirements for ESU delivery.  At a minimum please ensure that you read through https://learn.microsoft.com/en-us/azure/azure-arc/servers/license-extended-security-updates - and if this is unclear and you are still uncertain, please work with your local Microsoft licensing expert to ensure that you are not breaking licensing compliance.

## CRITICAL IMPORTANCE 
**Do not add MSDN/Visual Studio licensed dev/test/nonprod servers to your deployment list! Those must be linked to a production server license and tagged specially. That is still a manual process in the Azure Portal which is relatively simple and straightforward, even at scale. You will be billed for dev/test licenses if you create specific licenses for them!**

# Pre-requisites:
Tested on PowerShell 7.3.7 with PowerShell Az module 10.3.0 - running on prior versions will generate errors.
You will need the Az.ConnectedMachine PowerShell module which can be installed by running
```powershell
Install-Module az.connectedmachine -scope currentuser
```

# Preparing arc-esu.csv
### Please do not change headings on the CSV which will break the script
+ ServerName: Name of the server in Arc. All licenses will be named ServerName-ESU
+ Edition: Standard or Datacenter
+ LicenseType: vCore or pCore
+ CoreCount: 8 or higher for vCore, 16 or more for pCore
+ TargetSubscriptionID: Subscription hosting the Arc servers and licenses
+ MachineResourceGroupName: RG where the Arc machines live
+ LicenseResourceGroupName: RG where the licenses should be created (can be the same RG and often preferable)

# Please note:
This information is being provided as-is with the terms of the MIT license, with no warranty/guarantee or support. It is free to use - and for demonstration purposes only. The process of hardening this for your needs is a task I leave to you.