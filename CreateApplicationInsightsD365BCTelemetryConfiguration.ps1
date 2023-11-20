#Name of the Application Insights Resource
$appInsightsName = "YOURAPPLICATIONINSIGHTSNAME"

#Name of the Resource Group to use.
$resourceGroupName = "YOURRESOURCEGROUPNAME"

#Name of the workspave
$WorkspaceName = "YOURWORKSPACENAME"

#Azure location
$Location = "westeurope"

#Data retention for Application Insights (days)
$dataretentiondays = 30

#Daily Cap (GB) for Application Insights instance
$dailycap = 15

#Parameters for connecting to Dynamics 365 Business Central tenant
#Business Central tenant id
$aadTenantId = "TENANTID"     
#Name of the D365BC Environment
$D365BCenvironmentName = "YOURD365BCENVIRONMENTNAME"
#Partner's AAD app id
$aadAppId = "CLIENTID"        
#Partner's AAD app redirect URI
$aadAppRedirectUri = "nativeBusinessCentralClient://auth" 

Connect-AzAccount

New-AzResourceGroup -Name $resourceGroupName -Location $Location

New-AzOperationalInsightsWorkspace -Location $Location -Name $WorkspaceName -ResourceGroupName $resourceGroupName
$Resource = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $resourceGroupName
$workspaceId = $Resource.ResourceId

New-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $appInsightsName -location $Location -WorkspaceResourceId $workspaceId
$Resource = Get-AzResource -ResourceType Microsoft.Insights/components -ResourceGroupName $resourceGroupName -ResourceName $appInsightsName
$connectionString = $resource.Properties.ConnectionString
Write-Host "Connection String = " $connectionString
#Set data retention
$Resource.Properties.RetentionInDays = $dataretentiondays
$Resource | Set-AzResource -Force
#Set daily cap (GB)
Set-AzApplicationInsightsDailyCap -ResourceGroupName $resourceGroupName -Name $appInsightsName -DailyCapGB $dailycap


# Load Microsoft.IdentityModel.Clients.ActiveDirectory.dll
Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\AzureAD\2.0.2.140\Microsoft.IdentityModel.Clients.ActiveDirectory.dll" # Install-Module AzureAD to get this


# Get access token
$ctx = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$aadTenantId")
$redirectUri = New-Object -TypeName System.Uri -ArgumentList $aadAppRedirectUri
$platformParameters = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList ([Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always)
$accessToken = $ctx.AcquireTokenAsync("https://api.businesscentral.dynamics.com", $aadAppId, $redirectUri, $platformParameters).GetAwaiter().GetResult().AccessToken

Write-Host $accessToken

$response = Invoke-WebRequest `
    -Method Post `
    -Uri    "https://api.businesscentral.dynamics.com/admin/v2.11/applications/businesscentral/environments/$D365BCenvironmentName/settings/appinsightskey" `
    -Body   (@{
                 key = $connectionString
              } | ConvertTo-Json) `
    -Headers @{Authorization=("Bearer $accessToken")} `
    -ContentType "application/json"
Write-Host "Responded with: $($response.StatusCode) $($response.StatusDescription)"