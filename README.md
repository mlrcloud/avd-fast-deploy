# Fast Deploy - Azure Virtual Desktop

This repository contains an Azure Bicep template to simplify the deployment of an Azure Virtual Desktop in a test or demo environment. 

## Identity scenarios

The following table summarizes identity scenarios that this template supports:

| Identity scenario  | Session hosts | User accounts | FSLogix Profile Container (pooled) | Bicep templates required |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| Azure AD + AD DS  | Joined to AD DS  | In Azure AD and AD DS, synchronized | Supported | The network configuration for provisioning Azure Virtual Desktop with different usage scenarios. <br>- **Using AD DS VMs in shared vnet**: [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN and Azure Firewall](https://github.com/mlrcloud/vwan-azfw-fast-deploy). <br>- **Using on-premise AD DS**: [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN, Azure Firewall and DNS Private Resolver](https://github.com/mlrcloud/vwan-azfw-dnsresolver).|
| Azure AD + AD DS  | Joined to Azure AD  | In Azure AD and AD DS, synchronized | Supported | The network configuration for provisioning Azure Virtual Desktop with different usage scenarios. <br>- **Using AD DS VMs in shared vnet**: [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN and Azure Firewall](https://github.com/mlrcloud/vwan-azfw-fast-deploy). <br>- **Using on-premise AD DS**: [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN, Azure Firewall and DNS Private Resolver](https://github.com/mlrcloud/vwan-azfw-dnsresolver).|
| Azure AD only  | Joined to Azure AD  | In Azure AD | Not supported. User accounts must be hybrid identities, which means you'll also need AD DS and Azure AD Connect. You must create these accounts in AD DS and synchronize them to Azure AD. | <br>- [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN, Azure Firewall and DNS Private Resolver](https://github.com/mlrcloud/vwan-azfw-dnsresolver).|


All network elements are provided by the mentioned repositories, but if you want to use your custom environment, please refer to the specific question in this file.

The following diagram shows a detailed global architecture of the logical of the resources created by this template. Relevant resources for the specific scenario covered in this repository are deployed into the following resource groups:

![Global architecture](/doc/images/networking/general-deployment.png)

- **rg-avd**: network configuration for provisioning Azure Virtual Desktop with different usage scenarios.
- **rg-asr**: disaster recovery resources for personal desktop scenario.
- **rg-monitor**: a storage account and a Log Analytics Workspace to store the diagnostics information.
- **rg-images**: image Builder resources required for image management.
- **rg-profiles**: a storage account for roaming profiles.

The following diagram shows a detailed architecture of the network topology of the resources created by this template for a personal desktop scenario. Scenario bellow corresponds to the scenario "Azure AD only" in **[Identity scenarios](#Identity-scenarios)**.

![Logical architecture](/doc/images/networking/networking-dr-pers.png)

## Repository structure

This repository is organized in the following folders:

- **avd**: folder containing Bicep file that deploy the environment. Inside this folder the following files are available:
  - `environment`: templates to deploy a hostpool (pooled or personal) resources, scaling plan (only for pooled hostpool), desktop application group, remoteapp application group (only for pooled hostpool) and a workspace.
  - `addHost`: templates to deploy the required modules to add new session hosts to an existing pool previously created with the environment templates.
  - `iam`: deploys virtual desktop autoscale role resources.
- **asr**: templates to deploy disaster recovery resources for personal pool scenario.
- **doc**: contains documents and images related to this scenario.
- **modules**: Bicep modules that integrates the different resources used by the base scripts.
- **utils**: extra files required to deploy this scenario.

## Prerequisites

Bicep is the language used for defining declaratively the Azure resources required in this template. You would need to configure your development environment with Bicep support to succesfully deploy this scenario.

- [Installing Bicep with Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- [Installing Bicep with Azure PowerShell](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-powershell)

As alternative, you can use [Azure Shell with PowerShell](https://ms.portal.azure.com/#cloudshell/) that already includes support for Bicep.

After validating Bicep installation, you would need to configure the Azure subscription where the resources would be deployed. You need to make sure that you have at least enough quota for creating the required sessions hosts instances you define in the parameters file.

## How to deploy

1. Deploy the base Bicep template based on your **[Identity scenarios](#Identity-scenarios)** to have available the networking resources used by this template.
2. Customize the required parameters in parameters.personal.json o parameters.pooled.json files described in the Parameters section.
3. Add extra customizations if wanted to adapt their values to your specific environment.
4. Execute `deploy.PowerShell.ps1` or `deploy.CLI.ps1` script based on the current command line Azure tools available in your computer with the correct parameter file.
5. Wait around 10-15 minutes.
6. Enjoy.

### Custom Deployment

If you don't want to use any of the base Bicep templates for networking resources, you would need to have an Azure subscription with the following resources and pass the right values in the parameters file.

- A resource group where monitoring resources would be hosted.
- A Log Analytics workspace already created in the monitoring Resource Group.
- A resource group where the following resources should be deployed:
  - A vnet for virtual desktop workloads.
  - A subnet for the hostpool.
- Connectivity with an Active Directory Domain Services Controller or Azure Active Directory Domain Services instance.
- A storage account used by the diagnostics extension.

## Parameters

### Personal pool scenario
The following parameters are required to deploy *personal pool* scenario:

| Parameter | Type | Description | Default value |
| ------------- | ------------- | ------------- | ------------- |
| *roleDefinitions.X.principalId* | string | Replace this GUID with the Object ID of the Windows Virtual Desktop application created by default inside your Azure Active Directory. | 26da2792-4d23-4313-b9e7-60bd7c1bf0b1 |
| *avdConfiguration.workSpace.tokenExpirationTime* | string | Modify the expiration time between one hour ahead or 30 days of the actual time. | 03/05/2023 8:55:50 AM |

*The default parameter file contains all the possible options available in this environment. We recommend to adjust only the values of the parameters described here.*

| Parameter | Type | Description | Default value |
| ------------- | ------------- | ------------- | ------------- |
| *location* | string | Allows to configure the Azure region where the resources should be deployed. | westeurope |
| *resourceGroupNames* | string | Allows to configure the specific resource group where the resources associated to that serice would be deployed. You can define the same resource group name for all resources in a test environment to simplify management and deletion after finishing with the evaluation. | <br>- "monitoring": "rg-monitor", <br>- "avdNetworking": "rg-avd", <br>- "avd": "rg-avd-hp-data-pers", <br>- "shared": "rg-shared" |
| *deployFromScratch* | bool | If you are creating a new Azure Virtual Desktop environment you should keep this value as true. It would create all the required resources. If you already has an environment deployed and the only thing you want is to add new pools, change it to false. | true |
| *monitoringOptions.newOrExistingLogAnalyticsWorkspaceName* | string | If you want to use an existing Log Analytics Workspace make sure that the correct name is configured in this parameter. | law-demo |
| *monitoringOptions.diagnosticsStorageAccountName* | string | Storage account name for Diagnostic extension. | sadiagdataavd |
| *vmConfiguration.aadLogin* | bool | If you want to join VM to AAD you should keep this value as `true`. In case you keep this value as `false`, you should configure the domainConfiguration parameters. | true |
| *vmConfiguration.prefixName* | string | Provide the prefix name for your session hosts. | vmshdataps |
| *vmConfiguration.sku* | string | Select the instance type that best meets the performance requirements of your session hosts. | Standard_DS3_V2 |
| *vmConfiguration.redundancy* | string | Select either availabilityZone or availabilitySet. | availabilityZone |
| *vmConfiguration.availabilityZones* | array | Indicate the number of AZs to which you want to spread your session hosts. In case you use availabilitySet, this parameter is ignored. | [1,2,3] |
| *vmConfiguration.adminUsername* | string | User name of the local admin configured in every virtual machine deployed. | azureAdmin |
| *vmConfiguration.image.imageId* | string | Indicate a `imageId` of an already deployed image version from an Azure Gallery. In case you want to use a custom image, you should keep this value empty and indicate the `imageOffer`, `imageSKU`, `imagePublisher` and `imageVersion` parameters. | <br>- "imageId": "/subscriptions/XXXXXXXXXXXXX/resourceGroups/rg-images/providers/Microsoft.Compute/galleries/gallery/images/WVD10_Pers_Definition/versions/1.0.0", "imageOffer": "Windows-10", "imageSKU": "20h2-ent", "imagePublisher": "MicrosoftWindowsDesktop", "imageVersion": "latest" | 
| *vmConfiguration.domainConfiguration* | object | Modify the properties in this object to adjust it to your current Active Directoy Domain details. | <br>- "name":  "mydomain.local", <br>- "ouPath": "OU=Personal,OU=AVD,DC=mydomain,DC=local", <br>- "vmJoinUserName": "azureAdmin" |
| *vmConfiguration.networkConfiguration* | object | Provide the names of the vnet and subnet where session hosts will be deployed. | <br>- "vnetName": "vnet-avd", <br>- "subnetName": "snet-avd-hp-data-pers" |
| *avdConfiguration.workspaces.placeholderWorkspace.deployWorkspace* | bool | If you want to deploy a placeholder workspace for initial feed discovery through a private endpoint, you should keep this value as `true`. In case you already have a placeholder workspace deployed or you don't want to use private endpoint for initial feed discovery, you should keep this value as `false` and the rest of the parameters in this object will be ignored. | true |
| *avdConfiguration.workspaces.placeholderWorkspace.name* | string | Provide a name for the placeholder workspace. | ws-placeholder |
| *avdConfiguration.workspaces.placeholderWorkspace.deployDiagnostics* | bool | If you want to sent the diagnostic logs to Log Analytics Workspace, you should keep this value as `true`. | true |
| *avdConfiguration.workspaces.placeholderWorkspace.privateLink* | object | If you want to use the placeholder workspace for initial feed discovery through a private endpoint, you should keep *deployPrivateLink* value as `true`. In case you keep this value as `false`, initial feed discovery flow will be done through the public endpoint and the rest of the parameters in this object will be ignored. | "deployPrivateLink": true |
| *avdConfiguration.workspaces.placeholderWorkspace.privateLink.publicNetworkAccess* | string | `Enabled` allows the placeholder workspace to be accessed from both public and private networks, `Disabled` allows the placeholder workspace to only be accessed via private endpoints. | Enabled |
| *avdConfiguration.workspaces.feedWorkspace.deployWorkspace* | bool | If you want to deploy a feedWorkspace workspace for feed download through a private endpoint, you should keep this value as `true`. In case you already have a feedWorkspace workspace deployed, you should keep this value as `false` and the rest of the parameters in this object will be ignored. | true |
| *avdConfiguration.workspaces.feedWorkspace.name* | string | Provide a name for the feed workspace. | ws-avd-datapers |
| *avdConfiguration.workspaces.feedWorkspace.deployDiagnostics* | bool | If you want to sent the diagnostic logs to Log Analytics Workspace, you should keep this value as `true`. | true |
| *avdConfiguration.workspaces.feedWorkspace.privateLink* | object | If you want to enable feed download through private endpoint, you should keep *deployPrivateLink* value as `true`. In case you keep this value as `false`, the private endpoint will not be deployed and this workflow will be done through the public endpoint, and the rest of the parameters in this object will be ignored. | "deployPrivateLink": true |
| *avdConfiguration.workspaces.feedWorkspace.privateLink.publicNetworkAccess* | string | <br>- `Enabled` allows the feed workspace to be accessed from both public and private networks. <br>- `Disabled` allows the feed workspace to only be accessed via private endpoints. | Enabled |
| *avdConfiguration.hostpool.addHosts* | bool | If you already has an environment deployed and the only thing you want is to add new session hosts, you should keep this value as `true`. In case you keep this value as `false`, new session hosts will not be provisioned and the rest of the parameters in this object will be ignored. | true |
| *avdConfiguration.hostpool.name* | string | Provide a name for the hostpool. | hp-data-pers |
| *avdConfiguration.hostpool.instances* | string | Provide the number of session hosts you want to deploy. | 1 |
| *avdConfiguration.hostpool.currentInstances* | string | Provide the current number of session hosts in the hostpool. | 0 |
| *avdConfiguration.hostpool.type* | string | Select the type of hostpool you want to deploy. | Personal |
| *avdConfiguration.hostpool.assignmentType* | string | Select the assignment type of the hostpool. | Automatic |
| *avdConfiguration.hostpool.rdpProperties* | string | Provide RDP properties of the hostpool. To access Azure AD-joined VMs using the web, Android, macOS and iOS clients or from desktop clients running on local PC that doesn't meet one of [these](https://learn.microsoft.com/en-us/azure/virtual-desktop/azure-ad-joined-session-hosts#connect-using-the-windows-desktop-client) conditions, you must add `targetisaadjoined:i:1` as a custom RDP property to the host pool. | audiocapturemode:i:0;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectcomports:i:0;redirectprinters:i:0;redirectsmartcards:i:0;screen mode id:i:2;targetisaadjoined:i:1 |
| *avdConfiguration.hostpool.deployDiagnostics* | bool | If you want to sent the diagnostic logs to Log Analytics Workspace, you should keep this value as `true`. | true |
| *avdConfiguration.hostpool.privateLink.deployPrivateLink* | object | If you want to enable private endpoint for hostpool, you should keep *deployPrivateLink* value as `true`. In case you keep this value as `false`, the private endpoint will not be deployed and this workflow will be done through the public endpoint, and the rest of the parameters in this object will be ignored. | "deployPrivateLink": true |
| *avdConfiguration.hostpool.privateLink.publicNetworkAccess* | string | <br>- `Enabled` allows users to connect to the host pool using public internet or private endpoints and Azure Virtual Desktop session hosts will talk to the Azure Virtual Desktop service over public internet or private endpoints. <br>- `Disabled` allows users to only connect to host pool using private endpoints and Azure Virtual Desktop session hosts can only talk to the Azure Virtual Desktop service over private endpoint connections. <br>- `EnabledForSessionHostsOnly` allows Azure Virtual Desktop session hosts to talk to the Azure Virtual Desktop service over public internet or private endpoints. Users can only connect to host pool using private endpoints. <br>- `EnabledForClientsOnly` allows users to connect to the host pool using public internet or private endpoints. Azure Virtual Desktop session hosts can only talk to the Azure Virtual Desktop service over private endpoint connections. | Enabled |
| *avdConfiguration.applicationGroups.desktopAppGroup.name* | string | Provide a name for the desktop application group. | hp-data-pers-dag |
| *avdConfiguration.applicationGroups.desktopAppGroup.deployDiagnostics* | bool | If you want to sent the diagnostic logs to Log Analytics Workspace, you should keep this value as `true`. | true |




