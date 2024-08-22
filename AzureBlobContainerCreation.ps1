################# Azure Blob Storage - PowerShell ####################  
 
## Input Parameters  
$resourceGroupName="YOUR_RESOURCE_GROUP_NAME"  
$storageAccountName="YOUR_STORAGE_ACCOUNT_NAME"  
$storageContainerName="YOUR_CONTAINER_NAME"   
 
## Connect to Azure Account  
Connect-AzAccount   
 
## Function to create the storage container  
Function CreateStorageContainer  
{  
    Write-Host "Creating storage container.."  
    ## Get the storage account in which container has to be created  
    $storageAccount=Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName      
    ## Get the storage account context  
    $ctx=$storageAccount.Context      
 
    ## Check if the storage container exists  
    if(Get-AzStorageContainer -Name $storageContainerName -Context $ctx -ErrorAction SilentlyContinue)  
    {  
        Write-Host $storageContainerName "- container already exists."  
    }  
    else  
    {  
       Write-Host $storageContainerName "- container does not exist."   
       ## Create a new Azure Storage Account  
       New-AzStorageContainer -Name $storageContainerName -Context $ctx -Permission Container  
    }       
}   
  
CreateStorageContainer   
 
## Disconnect from Azure Account  
Disconnect-AzAccount 
