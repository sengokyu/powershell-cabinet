Set-StrictMode -Version Latest

<#
.SYNOPSIS
Associate a schedule  to the Stop virtual machine runbook.

.EXAMPLE
Register-AzureRmStopVmScheduleRunbook -ResourceGroupName rg01 -AutomationAccountName aa01 -VmName myvm -ScheduleName NineOclock

#>
function Register-AzureRmStopVmScheduleRunbook {
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

    [String]$RunbookName = 'Stop-SingleAzureRmVm'

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
