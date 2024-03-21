##########################################################################################
# Checks for available updates for AppSource apps installed on a given tenant
##########################################################################################
$clientid     = "YOUR_CLIENT_ID"
$clientsecret = "YOUR_CLIENT_SECRET"
$scope        = "https://api.businesscentral.dynamics.com/.default"
$tenant       = "YOUR_TENANT_ID"
$environment  = "YOUR_ENVIRONMENT_NAME"
# Get access token
$token = Get-MsalToken `
         -ClientId $clientid `
         -TenantId $tenant `
         -Scopes $scope `
         -ClientSecret (ConvertTo-SecureString -String $clientsecret -AsPlainText -Force)
$accessToken = ConvertTo-SecureString -String $token.AccessToken -AsPlainText -Force

# Get available updates
$response= Invoke-WebRequest `
    -Method Get `
    -Uri    "https://api.businesscentral.dynamics.com/admin/v2.1/applications/businesscentral/environments/$environment/apps/availableUpdates" `
    -Authentication OAuth `
    -Token $accessToken

if ((ConvertFrom-Json $response.Content).value.length -gt 0) {
    $jsonresponse = ConvertFrom-Json $response.Content
    $mailBody = "<b><u>APP UPDATES AVAILABLE:</u></b> <br>"
    foreach($app in $jsonresponse.value)
    {   
        $mailBody += "<b>App ID:</b> " + $app.id + " <b>Name:</b> " + $app.name + " <b>Publisher:</b> " + $app.publisher + " <b>Version:</b> " + $app.version  + "<br>"
    }
}
else {
    Write-Output "NO APP UPDATES FOUND."
    $mailBody = "";
}

if ($mailBody.Length -gt 0)
{
    #Sending a notification email
    $UserName = "YOUR_SMTP_USERNAME"
    $Password = "YOUR_SMTP_PASSWORD"
    $from = "YOUR_SENDING_EMAIL_ADDRESS";
    $to = "YOUR_RECEIVING_EMAIL_ADDRESS";
    $SecurePassword = ConvertTo-SecureString -string $password -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential -argumentlist $UserName, $SecurePassword
    $EmailParams = @{
        From = $from
        To = $to
        Subject = "APP UPDATES AVAILABLE FOR TENANT " + $tenant
        Body = $mailBody
        SmtpServer = "smtp.office365.com"
        Port = 587
        UseSsl = $true
        Credential = $Cred
        BodyAsHtml = $true
    }
    Send-MailMessage @EmailParams
}
