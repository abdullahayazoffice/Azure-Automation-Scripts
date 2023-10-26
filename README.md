# Azure-Automation-Scripts
Absolutely, I can include the script parts within the breakdown section. Here's the revised article:

---

# Automating CosmosDB Security with PowerShell

## Introduction

CosmosDB, a globally distributed, multi-model database service, is a critical part of many Azure-based applications. However, it poses a challenge when adding new Virtual Network (VNet) subnets. By default, it removes existing subnets. This article introduces a PowerShell script that resolves this issue by working in append mode.

## Prerequisites

Before running the script, make sure you have:

- Azure PowerShell module installed.
- Sufficient permissions to access and modify the specified Resource Groups and CosmosDB accounts.

## The PowerShell Script

```powershell
# Initialize start time
$startTime = Get-Date

# Define Resource Groups and VNets
$resourceGroupNamevnettobeadded = "FirstVNETRG"
$resourceGroupNamevnettobeadded2 = "SecondVNETRG"
$resourceGroupName = "cosmosdb-RG"
$NameofRGsContainingvnet = @($resourceGroupNamevnettobeadded, $resourceGroupNamevnettobeadded2)

# Initialize VNet rule array
$vnetRule = @()

# Loop through specified Resource Groups
foreach ($NameofRGsContainingvnet in $NameofRGsContainingvnet) {
    $vnetss = Get-AzVirtualNetwork -ResourceGroupName $NameofRGsContainingvnet 

    # Loop through VNets in the Resource Group
    foreach ($vnets in $vnetss) {
        # ... (rest of the script)
    } 
}

# Fetch existing CosmosDB account
# ... (rest of the script)

# Enable Virtual Network Filtering
# ... (rest of the script)

# Final checks and result
# ... (rest of the script)
```

## Script Breakdown

### 1. **Setting the Stage**

This section initializes the start time and defines the Resource Groups and VNets involved.

```powershell
# Initialize start time
$startTime = Get-Date

# Define Resource Groups and VNets
$resourceGroupNamevnettobeadded = "FirstVNETRG"
$resourceGroupNamevnettobeadded2 = "SecondVNETRG"
$resourceGroupName = "cosmosdb-RG"
$NameofRGsContainingvnet = @($resourceGroupNamevnettobeadded, $resourceGroupNamevnettobeadded2)
```

### 2. **Looping through Resource Groups**

The script iterates through specified Resource Groups, allowing for multiple RGs to be processed.

```powershell
foreach ($NameofRGsContainingvnet in $NameofRGsContainingvnet) {
    $vnetss = Get-AzVirtualNetwork -ResourceGroupName $NameofRGsContainingvnet 
    # Loop through VNets in the Resource Group
    foreach ($vnets in $vnetss) {
        # ... (rest of the script)
    } 
}
```

### 3. **Handling Virtual Networks**

Within each RG, the script fetches and iterates through VNets.

```powershell
$vnetss = Get-AzVirtualNetwork -ResourceGroupName $NameofRGsContainingvnet 

# Loop through VNets in the Resource Group
foreach ($vnets in $vnetss) {
    # ... (rest of the script)
} 
```

### 4. **Modifying Service Endpoints**

This section dynamically enables the CosmosDB service endpoint for each subnet, ensuring it's only added if not present already.

```powershell
foreach ($subnet in $vnets.Subnets) {
    $array = ($subnet | Select-Object Name , AddressPrefix)
    $subnetName = $array.Name
    $subnetPrefix = $array.AddressPrefix

    # Modify Service Endpoints
    Write-Host "Modifying Service Endpoints for subnet: $subnetName of the $vnetName" -fore red -back white
    $vnets2 = Get-AzVirtualNetwork -ResourceGroupName $NameofRGsContainingvnet | Get-AzVirtualNetworkSubnetConfig -Name $subnetName 3>$NULL
    $ServiceEndPoint2 = New-Object 'System.Collections.Generic.List[String]'
    $vnets2.ServiceEndpoints | ForEach-Object { $ServiceEndPoint2.Add($_.service) }
    if ($ServiceEndPoint2 -notcontains $newEndPoint) {
        $ServiceEndPoint2.Add($newEndpoint)
    }
    $delegation = $vnets2.Delegations

    # Apply changes
    Get-AzVirtualNetwork `
        -ResourceGroupName $NameofRGsContainingvnet  `
        -Name $vnetName | Set-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPrefix -ServiceEndpoint $ServiceEndPoint2 -Delegation $delegation | Set-AzVirtualNetwork 3> $NULL

    $subnetId = $vnets.Id + "/subnets/" + $subnetName
    $vnetRule += @(New-AzCosmosDBVirtualNetworkRule -Id $subnetId)
}
```

### 5. **CosmosDB Virtual Network Rules**

The script handles the CosmosDB virtual network rules, combining existing rules with newly created ones.

```powershell
# Fetch existing CosmosDB account
$accountName = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName

# Check if CosmosDB account is found
# ... (rest of the script)

# Fetch and append previously whitelisted VNets
# ... (rest of the script)
```

### 6. **Enabling Virtual Network Filtering**

It enables virtual network filtering for the CosmosDB account, with a note on potential time considerations.

```powershell
# Enable Virtual Network Filtering
Write-Output "Adding the CosmosDB account may take up to 12 minutes: $($accountName.Name)"
Update-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName.Name -EnableVirtualNetwork $true -VirtualNetworkRuleObject $vnetRule 
```

### 7. **Conclusion and Result**

Finally, the script provides feedback on the process, displaying the time taken for execution.

```powershell
# Final checks and result
$account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName.Name
$endtime = Get-Date
$result = $endtime - $startTime 
Write-Output $result
```

## Running the Script

1. Copy the script provided above.
2. Open a PowerShell window.
3. Paste the script and hit Enter.

## Conclusion

With this PowerShell script, you can seamlessly handle CosmosDB VNet subnet additions without worrying about existing configurations being removed. This automation ensures a smoother deployment process for your Azure-based applications.

---

Feel free to modify any part of the article to better suit your style and preferences. Happy writing!
