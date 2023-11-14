# Connect to Horizon and Vcenter
Connect-HVServer -Server ('HorizonServer') -Domain 'Domain'
Connect-VIServer -Server ('VcenterServer')
#Arrarys to hold good and bad results
$BadResults = @()
$GoodResults = @()
# Jumpbox Pools
$ProdPools = "Pool1", "Pool2", "Pool3", "Pool4"
# Get each machine in defined static pools that have users assigned and pass the name of those VMs from Horizon to Vcenter
foreach ($Pool in $ProdPools) {
    $CurrentMachines = Get-HVMachineSummary -PoolName $Pool | where-object { $_.NamesData.UserName -ne $null }
    $PassNames = $CurrentMachines.base.name
    foreach ($VM in $PassNames) {
        # Confirm that the Vcenter IP and DNS Ip record are the same. If so create an IP reservation in both DHCP servers
        $CurrentVm = Get-VM -Name $VM
        $VcenterIP = $CurrentVm.Guest | Select-Object -ExpandProperty IPAddress
        $DnsRecordIP = Resolve-DnsName -Name "$CurrentVm" | Select-Object -ExpandProperty IPAddress
        $MacAddress = $CurrentVm | Get-NetworkAdapter | Select-Object -ExpandProperty MacAddress
        $CurrentVMSummary = Get-HVMachineSummary -MachineName $CurrentVm.Name
        # Depending on the IP address place into appropriate DHCP Scope Id Reservation
        if ($DnsRecordIP -eq $VcenterIP) {
            if ($VcenterIP -like "10.0.199*") {
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer1' -ScopeId "10.0.199.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer2' -ScopeId "10.0.199.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
            }
            if ($VcenterIP -like "10.0.198*") {
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer1' -ScopeId "10.0.198.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer2' -ScopeId "10.0.198.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
            }
            if ($VcenterIP -like "10.0.197*") {
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer1' -ScopeId "10.0.197.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer2' -ScopeId "10.0.197.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
            }
            if ($VcenterIP -like "10.0.187*") {
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer1' -ScopeId "10.0.187.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
                Add-DhcpServerv4Reservation -ComputerName 'DHCPServer2' -ScopeId "10.0.187.0" -IPAddress "$VcenterIP" -ClientId "$($MacAddress.replace(':','-'))" -Description "Jumpbox IP Reservation" -Name "$CurrentVm"
            }
            # Custom object to export results
            $Result = [PSCustomObject]@{
                Name        = $CurrentVm.Name
                username    = $CurrentVMSummary.NamesData.UserName
                IP          = $VcenterIP
                Reservation = Get-DhcpServerv4Reservation  -ComputerName cci-dhcp3 -IPAddress $VcenterIP
            }
            $GoodResults += $Result
        }
        # If Ip did not match in Vcenter and DNS store in array
        else {
            write-host "The IP address did not match in Vcenter and Dns for $CurrentVm"
            $BadResults += "$($CurrentVm.name) `n"
        }
    }
}
# If any vm Ip does not match with both Vcenter and DNS export to csv for review
if ($BadResults -ne $null) {
    $BadResults | Export-Csv -Path C:\temp\MismatchedDnsVcenterIP.csv
}
# Export succesful results
if ($GoodResults -ne $null) {
    $GoodResults | Export-Csv -Path C:\Temp\JumpboxUserAndIps.csv
}
# Author: Tyler Travis
# Last updated - 11/13/2023
