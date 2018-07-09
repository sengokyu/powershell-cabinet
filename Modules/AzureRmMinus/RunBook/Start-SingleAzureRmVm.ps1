Workflow Start-SingleAzureRmVm {
    Param(
        [parameter(mandatory=$false)]
        [String]
        $CredentialAssetName = "AzureCredential",

        [parameter(mandatory=$false)]
        [String]
        $TenantIdAssetName = "TenantId",

        [parameter(mandatory=$true)]
        [String]
        $ResourceGroupName,

        [parameter(mandatory=$true)]
        [String]
        $VmName,

        [parameter(mandatory=$false)]
        [Boolean]
        $DryRun = $false
    )


    <#
    Login Azure RM
    #>
    function LoginAzureRm {
        param([String]$CredentialAssetName, [String]$TenantIdAssetName)

        $Cred = Get-AutomationPSCredential -Name $CredentialAssetName
        $TenantId = Get-AutomationVariable -Name $TenantIdAssetName

        if(!$Cred) {
            Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
        }

        Login-AzureRmAccount -ServicePrincipal -Credential $Cred -TenantId $TenantId
    }

    <#
    Returns true if Virtual Machine already started.
    #>
    function IsVmAllocated {
        param([String]$ResourceGroupName, [String]$VmName)
        
        $Vm = Get-AzureRmVM -Name $VmName -ResourceGroupName $ResourceGroupName -Status -ErrorAction Continue
        
        if (!$Vm) {
            Throw "Virtual machine '${VmName}' not found in Resource Group '${ResourceGroupName}'."
        }

        $Status = $Vm.Statuses | ?{ $_.Code -eq "PowerState/deallocated" }

        $Status -eq $null
    }

    <#
    Start virtual machine.
    Rertrying 3 times until success.
    #>
    function StartVm {
        param([String]$ResourceGroupName, [String]$VmName)        

        $TryCount = 0

        Do {
            $TryCount++

            Write-Output "Trying to start Virtual Machine '${VmName}', Count=${TryCount}"

            $Result = Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VmName -ErrorAction Continue

            if ($Result.IsSuccessStatusCode) {
                Write-Output "Virtual Machine '${VmName}' started."
            }
            else {
                Write-Output "Virtual Machine '${VmName}' cannot start."
                Start-Sleep -Seconds 15
            }
        } while($TryCount -le 3 -and !$Result.IsSuccessStatusCode)
    }

    ############
    # Main
    ############
    LoginAzureRm -CredentialAssetName $CredentialAssetName -TenantIdAssetName $TenantIdAssetName

    if (IsVmAllocated -ResourceGroupName $ResourceGroupName -VmName $VmName) {
        Write-Output "Virtual machine '${VmName}' is already allocated."
    }
    else {
        if ($DryRun) {
            Write-Output "DryRun mode, nothing to do."
        } else {
            StartVm -ResourceGroupName $ResourceGroupName -VmName $VmName
        }
    }

}