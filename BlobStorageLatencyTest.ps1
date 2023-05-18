Connect-AzAccount

$blobUri = "YOUR_BLOB_URI"

#Download blob
$iterations = 100
$stopwatch = [System.Diagnostics.Stopwatch]::new()
$origProgressPref = $ProgressPreference

$rawResults   = [System.Collections.ArrayList]::new()
$regionResult = @{
    PSTypeName   = 'AzureRegionLatencyResult'
    Region       = 'westeurope'
    ComputerName = $env:COMPUTERNAME
}

$ProgressPreference = 'SilentlyContinue'
for ($i = 0; $i -lt $iterations; $i++) {
    $stopwatch.Start()
    Invoke-WebRequest -Uri $blobUri -UseBasicParsing > $null
    $stopwatch.Stop()

    $rawResults.Add($stopwatch.ElapsedMilliseconds) > $null

    $stopwatch.Reset()
}
$ProgressPreference = $origProgressPref

$regionResult.Average = ($rawResults | Measure-Object -Average).Average
$regionResult.Minimum = ($rawResults | Measure-Object -Minimum).Minimum
$regionResult.Maximum = ($rawResults | Measure-Object -Maximum).Maximum

$finalResult = [PSCustomObject]$regionResult

$finalResult


#UPLOAD BLOB
$StorageAccount = "YOURSTORAGEACCOUNT";
$ContainerName = "YOURCONTAINERNAME";
$Context = New-AzStorageContext -StorageAccountName $StorageAccount -UseConnectedAccount
$Blob = @{
  File             = 'C:\Temp\test.pdf'
  Container        = $ContainerName
  Blob             = 'test.pdf'
  Context          = $Context
}

$iterations = 100
$stopwatch = [System.Diagnostics.Stopwatch]::new()
$origProgressPref = $ProgressPreference

$rawResults   = [System.Collections.ArrayList]::new()
$regionResult = @{
    PSTypeName   = 'AzureRegionLatencyResult'
    Region       = 'westeurope'
    ComputerName = $env:COMPUTERNAME
}

$ProgressPreference = 'SilentlyContinue'
for ($i = 0; $i -lt $iterations; $i++) {
    $stopwatch.Start()
    Set-AzStorageBlobContent @Blob -Force
    $stopwatch.Stop()

    $rawResults.Add($stopwatch.ElapsedMilliseconds) > $null

    $stopwatch.Reset()
}
$ProgressPreference = $origProgressPref

$regionResult.Average = ($rawResults | Measure-Object -Average).Average
$regionResult.Minimum = ($rawResults | Measure-Object -Minimum).Minimum
$regionResult.Maximum = ($rawResults | Measure-Object -Maximum).Maximum

$finalResult = [PSCustomObject]$regionResult

$finalResult