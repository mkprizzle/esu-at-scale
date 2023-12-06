[CmdletBinding()]

#------------------------------------------------------------------------------------------------------------------#
############################################## IMPORTANT NOTE ######################################################
################################## DO NOT PLACE MSDN/VISUAL STUDIO LICENSED ########################################
#################################### DEV/TEST/NONPROD SERVERS IN THE CSV ###########################################
############################ THESE ARE LICENSED SEPARATELY! MANUALLY LINK THEM #####################################
############################### TO A PRODUCTION LICENSE IN THE AZURE PORTAL ########################################
##################################### OR YOU WILL BE CHARGED FOR THEM! #############################################
######################################## ~Your friendly Azure CSA ##################################################
# https://learn.microsoft.com/en-us/azure/azure-arc/servers/deliver-extended-security-updates#additional-scenarios #
#------------------------------------------------------------------------------------------------------------------#


<#
.SYNOPSIS
    This script will create and link new ESU licenses or activate and link deactivated ESU licenses for Windows 2012 machines.

.DESCRIPTION
    This script will create and link new ESU licenses or activate and link deactivated ESU licenses for Windows 2012 machines.

.PARAMETER licenseOperation
    The operation to perform on the ESU license. Valid values are CreateAndLink, CreateDeactivatedOnly, ActivateAndLink

.PARAMETER TenantId
    The tenant ID of the Azure subscription.

.PARAMETER ApplicationId
    The application ID of the service principal.

.EXAMPLE
    .\esu_csv_bulk_operations.ps1 -licenseOperation CreateAndLink -TenantId "00000000-0000-0000-0000-000000000000" -ApplicationId "00000000-0000-0000-0000-000000000000" `
    -SecurePassword "00000000-0000-0000-0000-000000000000"
    
    This example will read arc-esu.csv, creating new licenses based on input data in an activated state and link them to the Arc machine

.EXAMPLE
    .\esu_csv_bulk_operations.ps1 -licenseOperation CreateDeactivatedOnly -TenantId "00000000-0000-0000-0000-000000000000 -ApplicationId "00000000-0000-0000-0000-000000000000" `
    -SecurePassword "00000000-0000-0000-0000-000000000000"
    
    This example will read arc-esu.csv, creating new licenses based on input data in an deactivated state, staged for later activation and linked. Used with ActivateAndLink command for staging licenses during contract negotiations

.EXAMPLE
    .\esu_csv_bulk_operations.ps1 -licenseOperation ActivateAndLink -TenantId "00000000-0000-0000-0000-000000000000 -ApplicationId "00000000-0000-0000-0000-000000000000" `
    -SecurePassword "00000000-0000-0000-0000-000000000000"
    
    This example will read arc-esu.csv, activate and link pre-staged deactivated licenses corresponding to machines in the list

.OUTPUTS
    The REST API response for the operation or in the case of the Create operation, the resource ID of the created license.
#>

param(
    [parameter(Mandatory=$true)]
    [ValidateSet("CreateAndLink","CreateDeactivatedOnly","ActivateAndLink")]
    $licenseOperation,

    [parameter(Mandatory=$true)]
    $TenantId,
    $ApplicationId
)

# If ServicePrincipal is used, connect to Azure with Service Principal and retrieve bearer token
[securestring]$SecurePassword = $(Read-Host -Prompt "Enter Client Secret" -AsSecureString)
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecurePassword
try {
    Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
    $token = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com').Token
}
catch {
    Write-Output "Failed to connect to Azure with Service Principal - Check your credentials"
    exit
}

# This works normally, but the context of the script is we want to be able to execute across all subscriptions
# a service principal is entitled to for scale so single subscription context is unwanted
#
# else {
#     try {
#        $context = Get-AzContext -ea 0
#        if ($context.Subscription -ne $subscriptionId) {
#         Set-AzContext -Subscription $subscriptionId
#         $token = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com').Token
#        }
#     }
#     catch{
#         Write-Output "No context found, logging in and setting context"
#         try{
#             Connect-AzAccount -Tenant $TenantId
#             Set-AzContext -Subscription $subscriptionId
#             $token = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com').Token
#         }
#         catch{
#             Write-Output "Failed to connect to Azure - Check your credentials"
#             exit
#         }
#     }
# }

Function Create-License {
    param (
        [parameter(Mandatory=$true)]
        $token,
        [parameter(Mandatory=$true)]
        $machineData,
        [parameter(Mandatory=$true)]
        $licenseOperation
    )

    # Create esu licenses
    foreach ($row in $machineData) {  
        # License variables
        $subscriptionId = $row.TargetSubscriptionID
        $licenseResourceGroupName = $row.LicenseResourceGroupName
        $machineResourceGroupName = $row.MachineResourceGroupName
        $serverName = $row.ServerName
        $licenseTarget = 'Windows Server 2012'
        $licenseEdition = $row.Edition
        $licenseType = $row.LicenseType
        $processors = $row.CoreCount
        $region = $row.Region
        if ($licenseOperation -eq 'CreateDeactivatedOnly') { $licenseState = 'Deactivated' }
        else { $licenseState = 'Activated' }

        # This is the generated resource id for the license - it might be helpful to name this off the machine for readability/ensure uniqueness.  
        $licenseResourceId = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.HybridCompute/licenses/{2}" -f $subscriptionId, $licenseResourceGroupName, $($serverName+"-ESU")   
    
        #create an ESU license  
        $createLicenseUrl =  "https://management.azure.com{0}?api-version=2023-06-20-preview" -f $licenseResourceId   
        $createBody = @{
            'location' = $region
            'properties' = @{
                'licenseDetails' = @{
                    'state' = $licenseState
                    'target' = $licenseTarget
                    "Edition" = $licenseEdition
                    "Type" = $licenseType
                    "Processors" = $processors
                }
            }
        }
        $bodyJson = $createBody | ConvertTo-Json -Depth 3
        $headers = @{
            Authorization = "Bearer $token"
        }
        Invoke-WebRequest -Uri $createLicenseUrl -Method Put -Body $bodyJson -Headers $headers -ContentType "application/json"

        if ($licenseOperation -eq 'CreateAndLink') {
            Link-License $token $machineData
        }
    }
}

Function Activate-License {
    param (
        [parameter(Mandatory=$true)]
        $token,
        [parameter(Mandatory=$true)]
        $machineData
    )

    foreach ($row in $machineData) {  
        $subscriptionId = $row.TargetSubscriptionID
        $licenseResourceGroupName = $row.LicenseResourceGroupName
        $serverName = $row.ServerName

        $licenseResourceId = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.HybridCompute/licenses/{2}" -f $subscriptionId, $licenseResourceGroupName, $($serverName+"-ESU") 

        # Activate the license
        $updateLicenseUrl =  "https://management.azure.com{0}?api-version=2023-06-20-preview" -f $licenseResourceId

        $licenseState = 'Activated'
        $updateBody = @{
            'properties' = @{
                'licenseDetails' = @{
                    'state' = $licenseState
                }
            }
        }
        $bodyJson = $updateBody | ConvertTo-Json -Depth 3

        $headers = @{
            Authorization = "Bearer $token"
        }
        Invoke-WebRequest -Uri $updateLicenseUrl -Method Patch -Body $bodyJson -Headers $headers -ContentType "application/json"
    }
}

Function Link-License {
    param (
        [parameter(Mandatory=$true)]
        $token,
        [parameter(Mandatory=$true)]
        $machineData
    )

    foreach ($row in $machineData) {
        $subscriptionId = $row.TargetSubscriptionID
        $licenseResourceGroupName = $row.LicenseResourceGroupName
        $machineResourceGroupName = $row.MachineResourceGroupName
        $serverName = $row.ServerName
        $region = $row.Region
        
        $licenseResourceId = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.HybridCompute/licenses/{2}" -f $subscriptionId, $licenseResourceGroupName, $($serverName+"-ESU") 
        $machineResourceId = (Get-AzConnectedMachine -Name $serverName -ResourceGroupName $machineResourceGroupName).Id
        $linkLicenseUrl = "https://management.azure.com{0}/licenseProfiles/default?api-version=2023-06-20-preview " -f $machineResourceId
        $linkBody = @{
            location = $region
            properties = @{
                esuProfile = @{
                    assignedLicense = $licenseResourceId
                }
            }
        }
        $bodyJson = $linkBody | ConvertTo-Json -Depth 3
        $headers = @{
            Authorization = "Bearer $token"
        }
        Invoke-WebRequest -Uri $linkLicenseUrl -Method PUT -Body $bodyJson -Headers $headers -ContentType "application/json"
    }
}

Function ActivateLink-License {
    param (
        [parameter(Mandatory=$true)]
        $token,
        [parameter(Mandatory=$true)]
        $machineData
    )

    Activate-License $token $machineData
    Link-License $token $machineData
}

$machineData = Import-Csv -Path ".\arc-esu.csv"

if ($licenseOperation -eq "CreateAndLink" -or $licenseOperation -eq "CreateDeactivatedOnly") {
    Create-License $token $machineData $licenseOperation
}
elseif ($licenseOperation -eq "ActivateAndLink") {
    ActivateLink-License $token $machinedata
}