import-module VMware.Hv.Helper
# Attempt to connect to Horizon view server
Try {
    Connect-HVServer -Server 'HorizonViewServer' -Domain 'Domain' -User #{ OD_SchedTaskUser } -Password #{ OD_SchedTaskUserPassword }
}
# Send an email if connection failed and stop script
Catch {
    $PSEmailServer = 'EmailServer.Domain'
    $CatchSubject = "Error in VDI script"
    $CatchBody = "Something went wrong with the Max User Count VDI script. Alert the virtualization teams unless prod changes are undergoing. Error: " + $Error[0]
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SystemAdminsDL@domain.com -Subject $CatchSubject -Body $CatchBody
    Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SOC-Team@domain.com -Subject $CatchSubject -Body $CatchBody
    throw
}
# Array of Production Pools to check for user counts
$ProdPools = Get-HVPool | Where-Object { $_.Base.DisplayName -like 'VDI_MFA*' -or $_.Base.DisplayName -eq 'Pool1' -or $_.Base.DisplayName -eq 'Pool2' -or $_.Base.DisplayName -eq 'Pool3' -or $_.Base.DisplayName -eq 'Pool4' -or $_.Base.DisplayName -eq 'Pool5' -or $_.Base.DisplayName -eq 'Pool6' }
$ProdPoolNames = $ProdPools.base.DisplayName
# For each pool in $ProdPools array get count of machines with users logged in
foreach ( $VDIPool in $ProdPoolNames) {
    # Get count of connected machines. The virtual machine is in an active session and has an active remote connection to a View client
    $VmList = Get-HVMachine -PoolName $VDIPool
    $ConnectedMachines = $VmList | where-object { $_.base.basicState -eq "Connected" }
    $ConnectedMachinesCount = $ConnectedMachines.Count
    # Get count of disconnected machines. The virtual machine is in an active session, but end user is currently disconnected
    $DisconnectedMachines = $VmList | where-object { $_.base.basicState -eq "DISCONNECTED" }
    $DisconnectedMachinesCount = $DisconnectedMachines.Count
    # Create a variable per pool to keep track of user count
    $TotalCount = $ConnectedMachinesCount + $DisconnectedMachinesCount
    New-Variable -Name "ConnectedCount$VDIPool"  -Value $TotalCount
}
# Get current user count
foreach ($VDIPool in $ProdPoolNames) {
    $variableName = "ConnectedCount$VDIPool"
    $TotalConnectedCount = Get-Variable -Name $variableName -ValueOnly
    write-host "the Max total for pool $VDIPool is: $TotalConnectedCount"
}
Start-Sleep -seconds 900
#######################################################
# initialize counter
$Counter = 0

# Check user counts every 15 mins for 8 hours
while ($Counter -le 32) {
    foreach ($VDIPool in $ProdPoolNames) {
        # Get count of machines that currently have users connected
        $VmList = Get-HVMachine -PoolName $VDIPool
        $ConnectedMachines = $VmList | where-object { $_.base.basicState -eq "Connected" }
        $ConnectedMachinesCount = $ConnectedMachines.Count
        # Get count of disconnected machines. The virtual machine is in an active session, but the user is currently disconnected from the View client
        $DisconnectedMachines = $VmList | where-object { $_.base.basicState -eq "DISCONNECTED" }
        $DisconnectedMachinesCount = $DisconnectedMachines.Count
        # Total user count
        $TotalCount = $ConnectedMachinesCount + $DisconnectedMachinesCount
        $variableName = "ConnectedCount$VDIPool"
        # If the new total user count if greater that the last recorded value, update the variable created for each pool with new value
        $CurrentCount = Get-Variable -Name $variableName -ValueOnly
        $CurrentTime = get-date
        if ($TotalCount -gt $CurrentCount) {
            Set-Variable -Name $variableName -Value $TotalCount
            write-host "Count has increased for Pool at $CurrentTime - $VDIPool the new max is $TotalCount"
        }
        else {
            Write-host "Count is the same for Pool at $CurrentTime - $VDIPool the max is still $CurrentCount"
        }
    }
    $Counter += 1
    write-host ''
    write-host ''
    start-sleep -Seconds 900
}
# Initialize array to store output
$Results = @()
# Get the final count for each pool and get the overall sum of all pools
foreach ( $VDIPool in $ProdPoolNames) {
    $variableName = "ConnectedCount$VDIPool"
    $TotalConnectedCount = Get-Variable -Name $variableName -ValueOnly
    write-host "the Max total for pool $VDIPool is: $TotalConnectedCount"
    $Results += "$VDIPool : $TotalConnectedCount `n"
    $OverallTotal += $TotalConnectedCount
}
# Get date
$Time = Get-Date -Format "MM-dd-yyyy"
# Email results
$PSEmailServer = 'EmailServer'
#$Results
$Subject = "VDI Max Pool Counts: $Time"
$Body = "Max user counts per pool - `n $Results   `n The Overall User Count is $OverallTotal"
Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SystemAdminsDL@domain.com -Subject $Subject -Body $Body
Send-MailMessage -Port 25 -From ScheduledTaskUser@domain.com -To SOC-Team@domain.com -Subject $Subject -Body $Body
# Author: Tyler Travis
# Last Updated 10/24
