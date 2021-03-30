#### AUTHENTICATION ####
# Import the ADAL module found in AzureRM.Profile
Import-Module AzureRM.Profile

#Application ID of the registered app
$appId = "YOUR_APPLICATION_ID"
#Client secret value for the app registration
$key = "YOUR_CLIENT_SECRET"
#AAD tenant ID
$tenantId = "YOUR_AAD_TENANT_ID"
#Azure Subscription ID
$subscriptionId = "YOUR_SUBSCRIPTION_ID"
#Resource group where Application Insight Instance is assigned to
$resourceGroupName = "YOUR_APPLICATION_INSIGHTS_RESOURCE_GROUP"
#Name of the Application Insight instance
$resourceName = "YOUR_APPLICATION_INSIGHTS_INSTANCE_NAME"

# Create the authentication URL and get the authentication context
$authUrl = "https://login.windows.net/${tenantId}"
$AuthContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]$authUrl

# Build the credential object and get the token form AAD
$credentials = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential -ArgumentList $appId,$key
$result = $AuthContext.AcquireToken("https://management.core.windows.net/",$credentials)
# Build the authorization header JSON object
$authHeader = @{
'Content-Type'='application/json'
'Authorization'=$result.CreateAuthorizationHeader()
}
#### END AUTHENTICATION ####




#### PURGE DATA ####
#Creates the API URI
$URI = "https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Insights/components/${resourceName}/purge?api-version=2015-05-01"

$body = @"
{
   "table": "customEvents",
   "filters": [
     {
       "column": "timestamp",
       "operator": "<",
       "value": "2018-01-01T00:00:00.000"
     }
   ]
}
"@

#Invoke the REST API to purge the data on Application Insights
$purgeID=Invoke-RestMethod -Uri $URI -Method POST -Headers $authHeader -Body $body
# Write the purge ID
Write-Host $purgeID.operationId -ForegroundColor Green
#### END PURGE DATA ####


#### GET PURGE STATUS ####
# Creation of the API URI to get the purge status
$purgeURI="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/${resourceGroupName}/providers/Microsoft.Insights/components/${resourceName}/operations/$($purgeID.operationId)?api-version=2015-05-01"
Invoke-RestMethod -Uri $purgeURI -Method GET -Headers $authHeader
#### END GET PURGE STATUS ####