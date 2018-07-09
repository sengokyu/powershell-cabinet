using namespace Microsoft.Azure.Commands.Profile.Models

Set-StrictMode -Version Latest

$script:ErrorActionPreference = "Stop"

<#
.SYNOPSIS
Create a new Automation Account which includes two RunBooks. Them makes start/stop a virtual machine.

.DESCRIPTION
This function creates seven objects in a resource group as follows 

 - ActiveDirectory Application
 - ActiveDirectory Service Principal
 - Automation Account
 - Variable Asset
 - Credential Asset
 - Runbook which makes start a virtual machine
 - Runbook which makes stop a virtual machine

.PARAMETER ResourceGroupName
A name of existing resource group.


.PARAMETER AutomationAccountName
A name of new automation account.


.EXAMPLE
New-AzureRmStartStopVmAutomation -ResourceGroupName rg01 -AutomationAccountName aa01


#>
function New-AzureRmStartStopVmAutomation {
    param(
        [parameter(mandatory=$true)]
        [String]
        $ResourceGroupName,

        [ValidateLength(6,50)]
        [parameter(mandatory=$true)]
        [String]
        $AutomationAccountName
    )

    [PSAzureContext]$Context = Get-AzureRmContext
    [String]$Location = (Get-AzureRmResourceGroup -Name $ResourceGroupName).Location
    [String]$ApplicationName = $AutomationAccountName + "_" + (New-Guid).ToString()
    [SecureString]$SecureString = ReadSecureString -Prompt "AD Application's Password:"
    [String]$Password = DecryptSecureString -SecureString $SecureString

    [String]$SubscriptionId = $Context.Subscription.SubscriptionId.ToString()
    [String]$TenantId = $Context.Tenant.TenantId.ToString()
    [String]$HomePage = "https://management.azure.com/subscriptions/${SubscriptionId}/resourcegroups/${ResourceGroupName}/providers/Microsoft.Automation/automationAccounts/${AutomationAccountName}"
    [String]$IdentifierUri = "https://spn/${ApplicationName}"
    [String[]]$RoleDefinitionNames = @("Reader","Virtual Machine Contributor")
    [String]$CredentialAssetName = "AzureCredential"
    [String]$TenantIdAssetName = "TenantId"
    [String]$MyModuleRoot = Split-Path -Path $PSScriptRoot -Parent

    try {
        # Create a new Application
        $NewApp = New-AzureRmADApplication `
            -DisplayName $ApplicationName `
            -Password $Password `
            -HomePage $HomePage `
            -IdentifierUris $IdentifierUri `
            -EndDate '9999-12-31'
        Write-Verbose -Message "Application Name='$($NewApp.DisplayName)' ApplicationId='$($NewApp.ApplicationId)' created."

        # Create a new Service Principal
        $NewSp = New-AzureRmADServicePrincipal `
            -ApplicationId $NewApp.ApplicationId
        Write-Verbose -Message "Service Principal Name='$($NewSp.ServicePrincipalName)' ObjectId='$($NewSp.Id)' created."

        # Wait for Service Principal avail
        Write-Verbose -Message 'Waiting for Service Principal.'
        $TmpSp = Get-AzureRmADServicePrincipal -ServicePrincipalName $NewSp.ServicePrincipalName
        while (!$TmpSp) {
            Start-Sleep -Seconds 1
            $TmpSp = Get-AzureRmADServicePrincipal -ServicePrincipalName $NewSp.ServicePrincipalName
        }

        # Assign Roles
        foreach ($i in $RoleDefinitionNames) {
            $null = New-AzureRmRoleAssignment `
                -ResourceGroupName $ResourceGroupName `
                -ServicePrincipalName $NewSp.ServicePrincipalName `
                -RoleDefinitionName $i
            Write-Verbose -Message "Role '${i}' assigned."
        }

        # Create a new Automation Account
        New-AzureRmAutomationAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $AutomationAccountName `
            -Location $Location
        Write-Verbose -Message "Automation Account '$($AutomationAccountName)' created in '${ResourceGroupName}'."
        
        # Create a Variable Asset
        $null = New-AzureRmAutomationVariable `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -Name $TenantIdAssetName `
            -Value $TenantId `
            -Encrypted $false
        Write-Verbose -Message "Variable Asset created in '${AutomationAccountName}'."

        # Create a Credential Asset
        $PsCred = New-Object `
            -TypeName System.Management.Automation.PSCredential `
            -ArgumentList $NewApp.ApplicationId,$SecureString

        $null = New-AzureRmAutomationCredential `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -Name $CredentialAssetName `
            -Value $PsCred
        Write-Verbose -Message "Credential Asset created in '${AutomationAccountName}'."

        # Import RunBooks
        $null = Import-AzureRmAutomationRunbook `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -Name "Start-SingleAzureRmVm" `
            -Type PowerShellWorkflow `
            -Path "$MyModuleRoot\RunBook\Start-SingleAzureRmVm.ps1" `
            -Published
        Write-Verbose -Message "RunBook 'Start-SingleAzureRmVm' imported."

        $null = Import-AzureRmAutomationRunbook `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -Name "Stop-SingleAzureRmVm" `
            -Type PowerShellWorkflow `
            -Path "$MyModuleRoot\RunBook\Stop-SingleAzureRmVm.ps1" `
            -Published
        Write-Verbose -Message "RunBook 'Stop-SingleAzureRmVm' imported."
    }
    catch [Exception] {
        Write-Host `
            -ForegroundColor $host.PrivateData.ErrorForegroundColor `
            -BackgroundColor $host.PrivateData.ErrorBackgroundColor `
            -Object $_.exception `
            -ErrorAction SilentlyContinue

        # Clean garbage.
        Remove-AzureRmAutomationAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $AutomationAccountName `
            -Force `
            -ErrorAction SilentlyContinue
        
        # the service principal also removed.
        if ($NewApp) {
            Remove-AzureRmADApplication `
                -ApplicationObjectId $NewApp.ApplicationObjectId `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}
