# Azure Arc Enabled Windows 2012 ESU At Scale
This is a repository that hosts a modified forked repo version of a sample set of scripted operations (Created by Adam Turner, modified by Jordan Norby) using the Resource Manager API (provided by management.azure.com) to perform the following operations at scale and based on real-world usage:
+ Create ESU licenses in an activated state and link them to many servers
+ Create deactivated ESU licenses for staging while payment terms are being negotiated
+ Activate and link staged ESU licenses to Windows 2012 machines

This updated script is parameterized for a larger set of idempotent operations and will help manage ESUs and their assignments at scale while the Product Groups are developing official SDK-based automation through CLI/PowerShell.

This version of the script takes feedback from real-world usage and the need for a single-run script that can handle a few ESU onboarding use cases previous scripts have not addressed with pushbutton convenience:
+ Multiple subscription/resource group cross-deployment
+ Multiple core type and core count deployment in a single run for massive deployment scenarios
+ Differentiated Create Only vs Create, activate, and link run scenarios which can be useful for staging and attaching later if contracts are still in progress
+ Link production licenses to MSDN/Visual Studio Dev/Test or DR servers for free ESU and tagging them appropriately
+ One-to-many license-to-server links, such as when a physical host license covers multiple VMs

This version of the script allows Service Principal only to enable cross-subscription ESU enablement if needed. Note that your service principal should have appropriate permissions to deploy ESU licenses and assign licenses to Arc Enabled Machines. The built-in role permission required to create and assign licenses to Arc-enabled machines is either "Contributor" or "Owner" roles. The least privilege method to run this script is to create a custom role based off of 'Azure Connected Machine Resource Administrator' with the added permissions:
+ Microsoft.HybridCompute/licenses/write
+ Microsoft.HybridCompute/machines/write
+ Microsoft.HybridCompute/machines/licenseProfiles/write

It is important to understand the underlying licensing requirements for ESU.  If you use this you are responsible for the licensing count and ensuring that the number of cores applied meet all licensing requirements for ESU delivery.  At a minimum please ensure that you read through https://learn.microsoft.com/en-us/azure/azure-arc/servers/license-extended-security-updates - and if this is unclear and you are still uncertain, please work with your local Microsoft licensing expert to ensure that you are not breaking licensing compliance.

## MSDN/Dev/Test/Visual Studio and DR Licensing
Dev/Test licensed under MSDN and DR instances [\(check if you benefit\)](https://www.microsoft.com/en-us/licensing/licensing-programs/software-assurance-by-benefits) can be linked to production licenses for free ESU. To do this, leave the licensing details out of the CSV (as seen in the example provided CSV) and input the production server the dev server is associated with under the `AssociatedProdServer` column. If the server falls under the DR benefit, check that box for proper tagging. The script will automatically skip creation of a license for the server and attempt to link the production server's license to it and then tag both the license and target server for compliance. **It is important that the production servers appear first in the CSV list to ensure the production license is created before attempting to link dev servers to it, or the script will fail**

**Do not use `AssociatedProdServer` with `AssociatedPhysicalHost` as these settings are incompatible**

https://learn.microsoft.com/en-us/azure/azure-arc/servers/deliver-extended-security-updates#additional-scenarios

## One-to-many Licensing Across Servers
You can create one license for multiple servers, such as the case when a physical host is being licensed for several VMs. Omit the licensing details such as core counts, editions and types in the CSV for servers you would like to associate to a host. Add the host (or server license you would like to assign to multiple VMsif not using physical host licensing) in the `AssociatedPhysicalHost` column. **It is important that the host server appears first in the CSV list to ensure the host license is created before attempting to link associated servers to it, or the script will fail**

**Do not use `AssociatedProdServer` with `AssociatedPhysicalHost` as these settings are incompatible**

# Pre-requisites:
Tested on PowerShell 7.3.7 with PowerShell Az module 10.3.0 - running on prior versions will generate errors.
You will need the Az.ConnectedMachine PowerShell module which can be installed by running
```powershell
Install-Module az.connectedmachine -scope currentuser
```

# Preparing arc-esu.csv
### Please do not change headings on the CSV which will break the script
+ **ServerName:** Name of the server in Arc. All licenses will be named ServerName-ESU
+ **Edition:** Standard or Datacenter
+ **LicenseType:** vCore or pCore
+ **CoreCount:** 8 or higher for vCore, 16 or more for pCore
+ **TargetSubscriptionID:** Subscription hosting the Arc servers and licenses
+ **MachineResourceGroupName:** RG where the Arc machines live
+ **LicenseResourceGroupName:** RG where the licenses should be created. This can be the same RG and is often preferable. **Make sure to create the resource group prior to running the script if not using the same RG as the arc machines as this script will not create the resource group for you!
+ **Region:** Azure region for the license to be created. Make sure the input is a valid Arc License region
+ **AssociatedPhysicalHost:** Enter a host server (or other shared license) from higher up the list to associate its license to this server. Do not use with `AssociatedProdServer`
+ **IsDR:** Enter any input here if the server is DR as entitled by software assurance. Used with `AssociatedProdServer`
+ **AssociatedProdServer:** Enter a production server from higher up the list to associate its license to this server. Use only for Dev/Test MSDN or DR servers as entitled. Do not use with `AssociatedPhysicalHost`
+ **IsPhysicalHost:** Fill this field if the server name specifies a physical host server running many VMs. A license will be created for the host but will not be linked to the host (as it is not connected to Arc) This is the host license that `AssociatedPhysicalHost` will attempt to link VM servers to. Licenses of this nature should typically be physical core licenses on Windows Server Datacenter edition

# Please note:
This information is being provided as-is with the terms of the MIT license, with no warranty/guarantee or support. It is free to use - and for demonstration purposes only. The process of hardening this for your needs is a task I leave to you.
