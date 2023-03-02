# Fast Deploy - Azure Virtual Desktop

This repository contains an Azure Bicep template to simplify the deployment of an Azure Virtual Desktop in a test or demo environment. 

## Identity scenarios

The following table summarizes identity scenarios that this template supports:

| Identity scenario  | Session hosts | User accounts | FSLogix Profile Container (pooled) | Bicep templates required |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| Azure AD + AD DS  | Joined to AD DS  | In Azure AD and AD DS, synchronized | Supported | The network configuration for provisioning Azure Virtual Desktop with different usage scenarios.
\- **Using AD DS VMs in shared vnet**: 
  - [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN and Azure Firewall](https://github.com/mlrcloud/vwan-azfw-fast-deploy).
- **Using on-premise AD DS**: 
  - [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN, Azure Firewall and DNS Private Resolver](https://github.com/mlrcloud/vwan-azfw-dnsresolver).|
| Azure AD + AD DS  | Joined to Azure AD  | In Azure AD and AD DS, synchronized | Supported |
The network configuration for provisioning Azure Virtual Desktop with different usage scenarios.
\- **Using AD DS VMs in shared vnet**: 
  - [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN and Azure Firewall](https://github.com/mlrcloud/vwan-azfw-fast-deploy).
- **Using on-premise AD DS**: 
  - [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN, Azure Firewall and DNS Private Resolver](https://github.com/mlrcloud/vwan-azfw-dnsresolver).|
| Azure AD only  | Joined to Azure AD  | In Azure AD | Not supported. User accounts must be hybrid identities, which means you'll also need AD DS and Azure AD Connect. You must create these accounts in AD DS and synchronize them to Azure AD. | 
\- [Fast Deploy: Hub-spoke network topology with Azure Virtual WAN, Azure Firewall and DNS Private Resolver](https://github.com/mlrcloud/vwan-azfw-dnsresolver).|


All network elements are provided by the mentioned repositories, but if you want to use your custom environment, please refer to the specific question in this file.

The following diagram shows a detailed global architecture of the logical of the resources created by this template. Relevant resources for the specific scenario covered in this repository are deployed into the following resource groups:

![Global architecture](/doc/images/networking/general-deployment.png)

- **rg-avd**: network configuration for provisioning Azure Virtual Desktop with different usage scenarios.
- **rg-asr**: Disaster recovery resources for personal desktop scenario.
- **rg-monitor**: a storage account and a Log Analytics Workspace to store the diagnostics information.
- **rg-images**: image Builder resources required for image management.
- **rg-profiles**: a storage account for roaming profiles.

The following diagram shows a detailed architecture of the network topology of the resources created by this template for a personal desktop scenario. Scenario bellow maps with scenario Azure AD only in **[Identity scenarios](#compatibility)**<br>.

![Logical architecture](/doc/images/networking/networking-dr-pers.png)

## Repository structure

This repository is organized in the following folders:

- **avd**: folder containing Bicep file that deploy the environment. Insid this folder the following files are available:
  - `environment`: templates to deploy a hostpool (pooled or personal) resources, scaling plan, desktop application group, remoteapp application group (only for pooled hostpool) and a workspace.
  - `addHost`: templates to deploy the required modules to add new session hosts to an existing pool previously created with the environment templates.
  - `iam`: deploys virtual desktop autoscale role resources.
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

1. Deploy <https://github.com/MS-ES-DEMO/vwan-azfw-consumption-play> repository to have available the networking resources used by this template.
2. Customize the required parameters in parameters.personal.json o parameters.pooled.json files described in the Parameters section .
3. Add extra customizations if wanted to adapt their values to your specific environment.
4. Execute `deploy.PowerShell.ps1` or `deploy.CLI.ps1` script based on the current command line Azure tools available in your computer with the correct parameter file.
5. Wait around 10-15 minutes.
6. Enjoy.

### Custom Deployment

If you don't want to use <https://github.com/MS-ES-DEMO/vwan-azfw-consumption-play> repository for networking resources, you would need to have an Azure subscription with the followin resources and pass the right values in the parameters file.

- A resource group where monitoring resources would be hosted.
- A Log Analytics workspace already created in the monitoring Resource Group.
- A resource group where the following resources should be deployed:
  - A vnet for virtual desktop workloads.
  - A subnet for the hostpool.
- Connectivity with an Active Directory Domain Services Controller or Azure Active Directory Domain Services instance.
- A storage account used by the diagnostics extension.

## Parameters

- *roleDefinitions.X.principalId*
  - "type": "string",
  - "description": "Replace this GUID with the Object ID of the Windows Virtual Desktop application created by default inside your Azure Active Directory."

- *avdConfiguration.workSpace.tokenExpirationTime*
  - "type": "string",
  - "description": "Modify the expiration time between one hour ahead or 30 days of the actual time".

*The default parameter file contains all the possible options available in this environment. We recommend to adjust only the values of the parameters described here.*

- *location*
  - "type": "string",
  - "description": "Allows to configure the Azure region where the resources should be deployed."

- *resourceGroupNames*
  - "type": "string",
  - "description": "Allows to configure the specific resource group where the resources associated to that serice would be deployed. You can define the same resource group name for all resources in a test environment to simplify management and deletion after finishing with the evaluation."

- *deployFromScratch*
  - "type": "bool",
  - "description": "If you are creating a new Azure Virtual Desktop environment you should keep this value as true. It would create all the required resources. If you already has an environment deployed and the only thing you want is to add new pools, change it to false."

- *newOrExistingLogAnalyticsWorkspaceName*
  - "type": "string",
  - "description": "If you want to use an existing Log Analytics Workspace make sure that the correct name is configured in this parameter."
  
- *vmConfiguration.adminUsername*
  - "type": "string",
  - "description": "User name of the local admin configured in every virtual machine deployed."

- *domainConfiguration*
  - "type": "object",
  - "description": "Modify the properties in this object to adjust it to your current Active Directoy Domain details.
