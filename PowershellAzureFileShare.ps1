Install-Module -Name Az -AllowClobber -Scope AllUsers

Connect-AzAccount

$location = 'West Europe';
$resourceGroupName = 'd365bcfilesharerg'
$storageAccountName = 'd365bcfilesharestorage'
$storageShareName = 'd365bcfileshare'
$driveLetterMapping = 'x'

#Create resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

#Create storage account
New-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName -Location $location -Type 'Standard_LRS'

#Retrieving references for the storage account
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName | select -first 1).Value
$storageContext = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey

#Create file share:
New-AzStorageShare -Name $storageShareName -Context $storageContext

#Creating a local drive
$secKey = ConvertTo-SecureString -String $storageKey -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\$($storageAccount.StorageAccountName)", $secKey

#Drive mapping (persistent)
#Open the regular PowerShell or Command Prompt to run these commands. If you run them as administrator, the drive won’t appear in File Explorer.
$root = "\\$($storageAccount.StorageAccountName).file.core.windows.net\$storageShareName"
Write-Output 'Mapping drive ' $driveLetterMapping' to ' $root
New-PSDrive -Name $driveLetterMapping -PSProvider FileSystem -Root $root -Credential $credential -Persist -Scope Global

#Temporary drives exist only in the current PowerShell session and in sessions that you create in the current session.
#Because temporary drives are known only to PowerShell, you can't access them by using File Explorer, Windows Management Instrumentation (WMI), Component Object Model (COM), Microsoft .NET Framework, or with tools such as net use.


#To remove the drive, use this cmdlet:
#Remove-PSDrive -Name $driveLetterMapping
