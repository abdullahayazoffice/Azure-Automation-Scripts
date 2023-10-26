$startTime = Get-Date

$resourceGroupNamevnettobeadded = "FirstVNETRG"
$resourceGroupNamevnettobeadded2 = "SecondVNETRG"
$resourceGroupName = "cosmosdb-RG"
 $NameofRGsContainingvnet = @($resourceGroupNamevnettobeadded,$resourceGroupNamevnettobeadded2) #you can add as many RGs as you want
 #script will add all the Vnets in the RGs provided in the list 

        $vnetRule = @()
       
        #array. to add more vnets simply add that vnet's RG in the array
        foreach ($NameofRGsContainingvnet in $NameofRGsContainingvnet) {
            #as all subnets of a vnet exisiting in the RG of the$NameofRGsContainingvnet has to be added so
            #fist fetching the vnet in the $vnets 
            $vnetss = Get-AzVirtualNetwork  -ResourceGroupName $NameofRGsContainingvnet 
            foreach ($vnets in $vnetss) {
    

                $vnetName = $vnets.Name

                #list of endpoint to append to already exisiting list of endpoints
                $newEndpoint = "Microsoft.AzureCosmosDB"

                
#below script will make sure to fetch all the subnets one by one and enable the service endpoint if not done already. 
#if service endpoint are already enabled then no change will be made

                foreach ($subnet in $vnets.Subnets) {
                    $array = ($subnet | Select-Object Name , AddressPrefix)
                    #getting the name of the subnets dynamically 

                    $subnetName = $array.Name
                    $subnetPrefix = $array.AddressPrefix
                    Write-Host "Modifying Service Endpoints for subnet: $subnetName of the $vnetName" -fore red -back white
                    $vnets2 = Get-AzVirtualNetwork  -ResourceGroupName $NameofRGsContainingvnet | Get-AzVirtualNetworkSubnetConfig -Name $subnetName 3>$NULL
                    $ServiceEndPoint2 = New-Object 'System.Collections.Generic.List[String]'
                    $vnets2.ServiceEndpoints | ForEach-Object { $ServiceEndPoint2.Add($_.service) }
                    if ($ServiceEndPoint2 -notcontains $newEndPoint) {
                        $ServiceEndPoint2.Add($newEndpoint)
                        
                    }
                    #If there is any delegations configured on the VNet then they are being stored to avoid any unintentional change
                    $delegation = $vnets2.Delegations
                    #the magic of adding the service endpoint 
                    Get-AzVirtualNetwork `
                        -ResourceGroupName $NameofRGsContainingvnet  `
                        -Name $vnetName | Set-AzVirtualNetworkSubnetConfig   -Name $subnetName   -AddressPrefix $subnetPrefix   -ServiceEndpoint $ServiceEndPoint2 -Delegation $delegation | Set-AzVirtualNetwork 3> $NULL
                    $subnetId = $vnets.Id + "/subnets/" + $subnetName
                    $vnetRule += @(New-AzCosmosDBVirtualNetworkRule  -Id $subnetId)
                    #$vnetrule is storing all the subnets which will be later whitelisted in cosmos db note that cosmosdb takes 12 minutes to update
                    #therefore all the subnets will be whitelisted at once to avoid time delays
                }
    
            } 
        }




#here the already whitelisted vnets are being fetched to later whitelist them 

        $accountName = Get-AzCosmosDBAccount  -ResourceGroupName $resourceGroupName
        if ($NULL -eq $accountName ) {
            continue
            Write-Output "no cosmos account is present in $resourceGroupName"
        }
            #copying previous stuff and then adding them
        $vnetids = $accountName.VirtualNetworkRules.Id
        foreach ($vnetid in $vnetids) {
 
            $subnetId = $vnetid
            $vnetRule += @(New-AzCosmosDBVirtualNetworkRule  -Id $subnetId)
        }
 
    
 



        write-output "adding the cosmosdb account may take 12 minutes  "   $accountName.Name

        Update-AzCosmosDBAccount   -ResourceGroupName $resourceGroupName    -Name $accountName.Name    -EnableVirtualNetwork $true    -VirtualNetworkRuleObject $vnetRule 
        $account = Get-AzCosmosDBAccount   -ResourceGroupName $resourceGroupName -Name $accountName.Name
        #add the echo of the RG name print 

$endtime = Get-Date

$result = $endtime - $startTime 
Write-Output $result