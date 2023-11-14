import-module VMware.Hv.Helper
# Connect to Horizon View Connection Server
Try {
    Connect-HVServer -Server 'HorizonServer' -Domain 'Domain.com' -User #{ OD_SchedTaskUser } -Password #{ OD_SchedTaskUserPassword }
}
Catch {
    $PSEmailServer = 'EmailServer'
    $CatchSubject = "Error in VDI script"
    $CatchBody = "Something went wrong with the After Hours Vm Creation VDI script. Alert the virtualization teams unless prod changes are undergoing. ****THIS IS A 911 IF THERE ARE NO CHANGES UNDERWAY**** Error: " + $Error[0]
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SystemAdminsDL@domain.com -Subject $CatchSubject -Body $CatchBody
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SOC-Team@domain.com -Subject $CatchSubject -Body $CatchBody
    throw
}
# Send email to SOC letting them know script has started and to watch for results email
$PSEmailServer = 'EmailServer'
$StartTime = Get-Date
$StartSubject = "SCRIPT STARTED AT: " + $StartTime
$StartBody = "The After Hours VDI Creation Script has now started. You will recieve another email in about 2 hours 35 mins informing you if the script was succesful or not. ***PLEASE ALERT THE VIRTUALIZATION TEAM IF THE SCRIPT FAILED OR IF YOU DO NOT RECEIVE THE EMAIL*** If it reports success please ignore. "
Send-MailMessage -From ScheduledTaskUser@domain.com -To SystemAdminsDL@domain.com -Subject $StartSubject -Body $StartBody
Send-MailMessage -From ScheduledTaskUser@domain.com -To SOC-Team@domain.com -Subject $StartSubject -Body $StartBody
# Define Production Pools
$ProdPools = Get-HVPool | Where-Object { $_.Base.DisplayName -like 'VDI_MFA*' -or $_.Base.DisplayName -eq 'Pool18' -or $_.Base.DisplayName -eq 'Pool8' -or $_.Base.DisplayName -eq 'Pool2' -or $_.Base.DisplayName -eq 'Pool13' -or $_.base.DisplayName -eq 'poo23' -or $_.base.DisplayName -eq 'pool5' }
$VdiPool = $ProdPools.base.DisplayName
foreach ($Pool in $VdiPool) {
    $VmList = Get-HVMachine -PoolName $Pool
    $DeleteVmNames = $VmList | where-object { $_.base.basicState -ne "AVAILABLE" }
    #Show Vms with active sessions and reset them
    $DeleteVmNames.base.name
    foreach ($Machine in $DeleteVmNames.base.name) {
        Reset-HVMachine $Machine -Confirm:$false
    }
}
Start-Sleep -Seconds 600
# Minimum Machine Count Values
$Pool_1Min = 325
$Pool2Min = 325
$x = 60
$x = 30
$x = 45
$x = 25
$x = 40
$Pool8min = 20
$x = 75
$x = 95
$x = 60
$x = 285
$x = 125
$x = 135
$x = 225
$x = 130
$x = 140
$Pool18Min = 110
# Set min machine count according to above and wait for Horizon to create machines^
Set-HVPool -PoolName 'Pool_1' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $Pool_1Min
start-sleep -Seconds 1200
Set-HVPool -PoolName 'Pool2' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $Pool2Min
Start-Sleep -Seconds 1200
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
start-sleep -Seconds 600
Set-HVPool -PoolName 'Pool8' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Start-Sleep -Seconds 600
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'Pool13' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Start-Sleep -Seconds 1200
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'x' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $x
Set-HVPool -PoolName 'Pool18' -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value $Pool18Min
Start-Sleep -Seconds 1200
# Vm's that did not create properly will be deleted and recreated. If a pool's provisoning stopped re-enable it. 2 Passes of this
foreach ($Pool in $VdiPool) {
    $ProvisonedPool = Get-HVPool -PoolName $Pool
    $ProvisionStatus = $ProvisonedPool.AutomatedDesktopData.VirtualCenterProvisioningSettings.EnableProvisioning
    if ($ProvisionStatus -eq $false) {
        Set-HVPool -PoolName $Pool -Key automatedDesktopData.virtualCenterProvisioningSettings.enableProvisioning -Value $true
    }
    $VmList = Get-HVMachine -PoolName $Pool
    $DeleteVmNames = $VmList | where-object { $_.Base.basicState -eq "ERROR" -or $_.Base.basicState -eq "ALREADY_USED" -or $_.Base.basicState -eq "AGENT_UNREACHABLE" }
    Remove-HVMachine -MachineNames $DeleteVmNames.base.name -DeleteFromDisk:$true -Confirm:$false
}
Start-Sleep -Seconds 900
foreach ($Pool in $VdiPool) {
    $ProvisonedPool = Get-HVPool -PoolName $Pool
    $ProvisionStatus = $ProvisonedPool.AutomatedDesktopData.VirtualCenterProvisioningSettings.EnableProvisioning
    if ($ProvisionStatus -eq $false) {
        Set-HVPool -PoolName $Pool -Key automatedDesktopData.virtualCenterProvisioningSettings.enableProvisioning -Value $true
    }
    $VmList = Get-HVMachine -PoolName $Pool
    $DeleteVmNames = $VmList | where-object { $_.Base.basicState -eq "ERROR" -or $_.Base.basicState -eq "ALREADY_USED" -or $_.Base.basicState -eq "AGENT_UNREACHABLE" }
    Remove-HVMachine -MachineNames $DeleteVmNames.base.name -DeleteFromDisk:$true -Confirm:$false
}
Start-Sleep -Seconds 900
# Check for VMs that are not synced correctly with AD. Delete and recreate them if not synced properly
Write-Host "Checking for non-synced VMs"
foreach ($Pool in $VdiPool) {
    $BadVmList = Get-HVMachine -PoolName $Pool | Where-Object { $_.ManagedMachineData.ViewComposerData.LastMaintenanceTime -eq $null }
    Remove-HVMachine -MachineNames $BadVmList.base.name -DeleteFromDisk:$true -Confirm:$false
}
Start-Sleep -Seconds 900
# Verfify that all machines have succesfully created and are available
$CheckCount = 0
$GoodStringArray = @()
$BadStringArray = @()
foreach ($Pool in $VdiPool) {
    $VmAvailable = Get-HVMachine -PoolName $Pool | Where-Object { $_.base.basicState -eq "AVAILABLE" }
    $VmMinPool = get-hvpool -PoolName $Pool
    $VmMinimum = $VmMinPool.AutomatedDesktopData.VmNamingSettings.PatternNamingSettings.MinNumberOfMachines
    # If the number of available machines is within 5 of the appointed number all is good
    if ($VmAvailable.count -ge ($VmMinimum - 5)) {
        Write-Host "Pool:' $Pool 'is ready for tomorrow `n"
        $GoodStringArray += "$Pool + :is ready for tomorrow and has -" + $VmAvailable.Count + "machines available `n"
        # Set minimum number of vms back to 10
        Set-HVPool -PoolName $Pool -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value 10
    }
    else {
        # If number of available machines is not within 5 of appointed number increase checkcount by 1 which later will trigger soc to get an email notifiying of failure
        $CheckCount += 1
        $BadStringArray += "$Pool + :is NOT ready for tomorrow and has -" + $VmAvailable.Count + "machines available `n"
        Write-host  $Pool + ":is NOT READY FOR TOMORROW"
        # Set minimum number of vms back to 10
        Set-HVPool -PoolName $Pool -Key automatedDesktopData.vmNamingSettings.patternNamingSettings.minNumberOfMachines -Value 10
    }
}
# Send out emails based on status of pools
if ($CheckCount -gt 0) {
    $PSEmailServer = 'EmailServer'
    $EndTime = Get-Date
    $Subject = "Script end @ $EndTime - Script FAILTURE: PRODUCTION POOLS ARE NOT READY FOR TOMORROW"
    $Body = "Something went wrong with the after hours creation VDI script. ***ALERT THE VIRTUALIZATION TEAM IMMEDIATELY UNLESS PRODUCTION CHANGES ARE UNDERGOING*** `n " + $BadStringArray
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SystemAdminsDL@domain.com -Subject $Subject -Body $Body
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SOC-Team@domain.com -Subject $Subject -Body $Body
    Write-Host "Failure!" + $BadStringArray
    Write-Host $CheckCount
}
else {
    $PSEmailServer = 'EmailServer'
    $EndTime = Get-Date
    $Subject = "Script end @ $EndTime - Script SUCCESS: VDI Pools Good To GO"
    $Body = "Production VDI Pools Are Ready For Tomorrow `n " + $GoodStringArray
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SystemAdminsDL@domain.com -Subject $Subject -Body $Body
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SOC-Team@domain.com -Subject $Subject -Body $Body
    Write-Host "Success"
    Write-Host $GoodStringArray
    Write-Host $CheckCount
}
# Author: Tyler Travis
# Last Updated: 10/11/2023
