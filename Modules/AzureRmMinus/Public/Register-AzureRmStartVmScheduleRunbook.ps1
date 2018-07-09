Set-StrictMode -Version Latest

<#
.SYNOPSIS
Associate a schedule  to the Start virtual machine runbook.

.EXAMPLE
Register-AzureRmStartVmScheduleRunbook -ResourceGroupName rg01 -AutomationAccountName aa01 -VmName myvm -ScheduleName NineOclock

#>
function Register-AzureRmStartVmScheduleRunbook {
    param(
        [parameter(mandatory=$true)]
        [String]
        $ResourceGroupName,

        [ValidateLength(6,50)]
        [parameter(mandatory=$true)]
        [String]
        $AutomationAccountName,

        [parameter(mandatory=$true)]
        [String]
        $VmName,

        [parameter(mandatory=$true)]
        [String]
        $ScheduleName
    )

    [String]$RunbookName = 'Start-SingleAzureRmVm'

    $ScheduleParams = @{
        ResourceGroupName=$ResourceGroupName;
        VmName=$VmName
    }

    Register-AzureRmAutomationScheduledRunbook `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Parameters $ScheduleParams `
        -RunbookName $RunbookName `
        -ScheduleName $ScheduleName
}
