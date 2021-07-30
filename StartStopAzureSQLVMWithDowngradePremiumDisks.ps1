Connect-AzAccount

$ResourceGroupName = "YOUR_VM_RESOURCE_GROUP"

$vmnames = get-AzVM -ResourceGroupName $ResourceGroupName -status
foreach ($vmname in $vmnames) 
{
    $vms = ((Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $vmname.name -Status).Statuses[1]).Code
    if ($vms -eq 'PowerState/running')
    {
        { 
            stop-AzVM -ResourceGroupName $ResourceGroupName -Name $vmname.name 
        }

        $vdisks = $vmname.StorageProfile.DataDisks

        foreach ($vdisk in $vdisks) {
        $d = Get-AzDisk -DiskName $vdisk.Name
            if ($d.sku.tier -eq "premium") {
                $storageType = 'Standard_LRS'   
                $d.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
                $d | Update-AzDisk
            }
        }
    }
}


$ResourceGroupName = "YOUR_VM_RESOURCE_GROUP"
$VM = "YOUR_VM_NAME"

$v=get-AzVM -ResourceGroupName $ResourceGroupName -VMName $VM 

$vms=((Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $VM -Status).Statuses[1]).Code
 

$vdisks=$v.StorageProfile.DataDisks

foreach ($vdisk in $vdisks)
{
    $d=Get-AzDisk -DiskName $vdisk.Name
   
    if ($d.sku.tier -eq "standard")
    {
        $storageType = 'Premium_LRS'   
        $d.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
        $d | Update-AzDisk
    }
}


if ($vms -ne 'PowerState/running')
{
    start-AzVM -ResourceGroupName $ResourceGroupName -Name $VM
}


