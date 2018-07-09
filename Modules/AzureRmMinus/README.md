# AzureRmMinus

Included functions are follows.

 - New-AzureRmStartStopVmAutomation
 - Register-AzureRmStartVmScheduleRunbook
 - Register-AzureRmStopVmScheduleRunbook

## New-AzureRmStartStopVmAutomation

This script create seven objects as follows.

 - ActiveDirectory Application
 - ActiveDirectory Service Principal
 - Automation Account
 - Variable Asset
 - Credential Asset
 - starting virtual machine RunBook
 - stopping virtual machine RunBook

Usage:

```
New-AzureRmStartStopVmAutomation -ResourceGroupName rg01 -AutomationAccountName aa01
```

## Register-AzureRmStartVmScheduleRunbook

Associate a schedule to the Start virtual machine runbook.

Usage:

First, you may create a schedule

```
New-AzureRmAutomationSchedule -ResourceGroupName rg01 -AutomationAccountName aa01 -Name mon9oclock -StartTime "2016-04-01 9:00" -DayInterval 7
```

Next, associate the schedule to the runbook.

```
Register-AzureRmStartVmScheduleRunbook -ResourceGroupName rg01 -AutomationAccountName aa01 -VmName vm01 -ScheduleName mon9oclock
```

## Register-AzureRmStopVmScheduleRunbook

Associate a schedule  to the Stop virtual machine runbook.

Usage:

```
Register-AzureRmStopVmScheduleRunbook -ResourceGroupName rg01 -AutomationAccountName aa01 -VmName vm01 -ScheduleName mon9oclock
```
