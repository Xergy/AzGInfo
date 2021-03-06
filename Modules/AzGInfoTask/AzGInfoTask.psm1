
Function Invoke-AzGInfoTaskVMs {
    [CmdletBinding()]
    param (
        # [parameter(mandatory = $true)]
        # $VMDetails,
        # [parameter(mandatory = $true)]
        # $MissingTag
    )

    Process {
        
        $Query = @"
Resources 
    | where type =~ 'microsoft.compute/virtualmachines'
    | extend 
        nicsCount=array_length(properties.networkProfile.networkInterfaces),
        resourceGroup,
        location,
        name,
        osType = tostring(properties.storageProfile.osDisk.osType),
        osDiskName = tostring(properties.storageProfile.osDisk.name),
        HybridUseBenefit = tostring(properties.licenseType),
        vmSize = tostring(properties.hardwareProfile.vmSize),
        osDiskCache = tostring(properties.storageProfile.osDisk.caching),
        dataDiskCount = array_length(properties.storageProfile.dataDisks),
        vNicCount = array_length(properties.networkProfile.networkInterfaces),
        avSet = tostring(properties.availabilitySet.id),
        tostring(tags)
        //nicId = tostring(nic.id)
    | project 
        tenantId,
        subscriptionId,
        location,
        resourceGroup,
        name,
        nicsCount,  
        osDiskName,
        osType,
        osDiskCache,
        HybridUseBenefit,
        vmSize,
        id
"@

    $TaskResults = Search-AzGraph -Query $Query -First 5000

        $Props = @{
            Title = "Virtual Machines"
            Description = "Azure VM Resource Details"
            ShortName = "VMs"
            Results = $TaskResults
            Total = $TaskResults.Count
            ReportWeight = "1000"  
        }
        
        Return (New-Object psobject -Property $Props)

    }
}

Function Invoke-AzGInfoTaskNics {
    [CmdletBinding()]
    param (
    )

    Process {
        
        $Query = @"
Resources
    | where type =~ 'microsoft.network/networkinterfaces'
    | extend 
        ipConfigsCount=array_length(properties.ipConfigurations),
        primary = properties.primary,
        AccelNet = properties.enableAcceleratedNetworking,
        IPForwarding = properties.enableIPForwarding,
        macAddress = properties.macAddress
    | project  
        tenantId,
        subscriptionId,
        location,
        resourceGroup,
        name,
        primary,
        AccelNet,
        IPForwarding,
        macAddress,
        id    
"@

    $TaskResults = Search-AzGraph -Query $Query -First 5000

        $Props = @{
            Title = "Network Interfaces"
            Description = "Azure Network Interfaces Resource Details"
            ShortName = "Nics"
            Results = $TaskResults
            Total = $TaskResults.Count
            ReportWeight = "2000"  
        }
        
        Return (New-Object psobject -Property $Props)

    }
}

Function Invoke-AzGInfoTaskIPConfigs {
    [CmdletBinding()]
    param (
    )

    Process {
        
        $Query = @"
Resources
    | where type =~ 'microsoft.network/networkinterfaces'
    | extend 
        ipConfigsCount=array_length(properties.ipConfigurations),
        nicName = name
    | mv-expand ipconfig=properties.ipConfigurations 
    | extend 
        nicId = id, 
        publicIpId = tostring(ipconfig.properties.publicIPAddress.id),
        ipconfigName = ipconfig.name,
        ipconfigId = ipconfig.id,
        AllocationMethod =ipconfig.properties.privateIPAllocationMethod,
        IPAddress = ipconfig.properties.privateIPAddress,
        primary = ipconfig.properties.primary,
        subnet = ipconfig.properties.subnet.id
    | project
        subscriptionId,
        location,
        resourceGroup,
        nicName, 
        ipconfigName,
        ipConfigsCount,
        AllocationMethod,
        IPAddress,
        subnet,
        ipconfigId 
"@

    $TaskResults = Search-AzGraph -Query $Query -First 5000

        $Props = @{
            Title = "Nic IP Config Configurations"
            Description = "Azure Nic IP Config Configurations Resource Details"
            ShortName = "IPConfigs"
            Results = $TaskResults
            Total = $TaskResults.Count
            ReportWeight = "2500"  
        }
        
        Return (New-Object psobject -Property $Props)

    }
}
Function Invoke-AzGInfoTaskPIPs {
    [CmdletBinding()]
    param (
    )

    Process {
        
        $Query = @"
Resources
    | where type =~ 'microsoft.network/publicipaddresses'
    | extend 
        publicIPAllocationMethod = properties.publicIPAllocationMethod,
        ipAddress = properties.ipAddress,
        fqdn = properties.dnsSettings.fqdn,
        ipConfigId = properties.ipConfiguration.id
    | project
        tenantId,
        subscriptionId,
        location,
        resourceGroup,
        name,
        publicIPAllocationMethod,
        ipAddress,
        fqdn,
        ipConfigId,
        id 
"@

    $TaskResults = Search-AzGraph -Query $Query -First 5000

        $Props = @{
            Title = "Public IP Addresses"
            Description = "Azure Public IP Address Resource Details"
            ShortName = "PIPs"
            Results = $TaskResults
            Total = $TaskResults.Count
            ReportWeight = "3000"  
        }
        
        Return (New-Object psobject -Property $Props)

    }
}

