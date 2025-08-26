<#
.SYNOPSIS
    Export guest users from Microsoft Entra ID (Azure AD) with detailed information, such as last login and account creation dates.

.DESCRIPTION
    This script connects to Microsoft Graph API to retrieve all guest users (`userType eq 'Guest'`) in Azure AD.
    It extracts the following information:
    - DisplayName (properly escaped if it contains commas or special characters)
    - Email
    - Account creation date
    - Days since account creation (if never logged in)
    - Last login date
    - Days since last login
    The results are exported to a user-specified CSV file.

.PARAMETER None
    No additional parameters are required. The script will prompt for the file save location.

.NOTES
    Version:        1.0.0

.REQUIREMENTS
    Before running the script, ensure you meet the following requirements:
    - Microsoft Entra ID (formerly Azure AD) – Your account must be linked to an Entra ID tenant.
    - Admin Role – Requires User.Read.All or higher permissions in Entra ID.
    - Microsoft Graph PowerShell Module – Installed automatically by the script if missing.
    - PowerShell Execution Policy – Must allow script execution (Set-ExecutionPolicy RemoteSigned).

Open PowerShell with elevated permissions (Run as Administrator).
Run the script using:
.\EntraIDGuestUsersExport.ps1

#>

# Ensure the script stops on errors
$ErrorActionPreference = "Stop"

# Function to display messages with timestamps
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
}

# Function to escape fields with special characters (e.g., commas)
function Escape-CsvField {
    param([string]$FieldValue)
    if ($FieldValue -and $FieldValue.Contains(",")) {
        return "`"$FieldValue`""  # Wrap the field in double quotes
    } else {
        return $FieldValue
    }
}

Write-Log "Starting Entra ID Guest User Export..."

# Prompt user to select a save location for the CSV file
Write-Log "Please choose where to save the output CSV file..."
$FileBrowser = New-Object -ComObject Shell.Application
$Folder = $FileBrowser.BrowseForFolder(0, "Select Folder to Save CSV File", 0)

if ($Folder) {
    $outputFolder = $Folder.Self.Path
    $outputFile = "$outputFolder\EntraIDGuestUsers_LastSignIn.csv"
} else {
    Write-Host "No folder selected. Using default script directory." -ForegroundColor Yellow
    $outputFile = "$PSScriptRoot\EntraIDGuestUsers_LastSignIn.csv"
}

Write-Log "CSV File will be saved as: $outputFile"

# Check if Microsoft Graph Users module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Log "Microsoft Graph module not found. Installing now..."
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Import only required Microsoft Graph submodule
Import-Module Microsoft.Graph.Users

# Connect to Microsoft Graph
Write-Log "Connecting to Microsoft Graph API..."
try {
    Connect-MgGraph -Scopes "User.Read.All" -ErrorAction Stop
    Write-Log "Connected successfully to Microsoft Graph."
} catch {
    Write-Host "ERROR: Failed to connect to Microsoft Graph. Ensure you have the correct permissions." -ForegroundColor Red
    exit
}

# Fetch all guest users with additional properties
Write-Log "Retrieving guest users from Microsoft Entra ID (Azure AD)..."
try {
    $guestUsers = Get-MgUser -Filter "userType eq 'Guest'" -Property Id, DisplayName, Mail, SignInActivity, CreatedDateTime -All
    Write-Log "Retrieved $($guestUsers.Count) guest users."
} catch {
    Write-Host "ERROR: Failed to retrieve guest users. Ensure you have the necessary permissions." -ForegroundColor Red
    exit
}

# Initialize an array to store the results
$results = @()

# Get the current date for calculation
$today = Get-Date

Write-Log "Processing users and cleaning data..."
foreach ($user in $guestUsers) {
    # Extract and clean data
    $displayName = if ($user.DisplayName) {
        Escape-CsvField($user.DisplayName.Trim() -replace "\s+", " ")  # Normalize spaces and wrap if needed
    } else {
        "Unknown Name"
    }

    $email = if ($user.Mail) {
        Escape-CsvField($user.Mail.Trim())  # Wrap email if it contains commas
    } else {
        "No Email Provided"
    }

    $createdDate = $user.CreatedDateTime
    $lastSignInDate = $user.SignInActivity.LastSignInDateTime

    # Calculate days since last login or creation
    $daysSinceLastLogin = if ($lastSignInDate) {
        ($today - $lastSignInDate).Days
    } else {
        "Never Logged In"
    }

    $daysSinceCreation = if (!$lastSignInDate -and $createdDate) {
        ($today - $createdDate).Days
    } else {
        ""
    }

    # Add a clean record to the results array
    $results += [PSCustomObject]@{
        DisplayName        = $displayName
        Email              = $email
        CreatedDate        = if ($createdDate) { $createdDate.ToString("dd-MM-yyyy HH:mm") } else { "Unknown" }
        DaysSinceCreation  = if ($daysSinceCreation -ne "") { $daysSinceCreation } else { "N/A" }
        LastSignIn         = if ($lastSignInDate) { $lastSignInDate.ToString("dd-MM-yyyy HH:mm") } else { "Never Logged In" }
        DaysSinceLastLogin = $daysSinceLastLogin
    }
}

# Export results to CSV
Write-Log "Exporting data to CSV file..."
try {
    $results | Export-Csv -Path $outputFile -NoTypeInformation
    Write-Log "Export completed successfully! File saved as: $outputFile"
} catch {
    Write-Host "ERROR: Failed to save the CSV file. Check file permissions." -ForegroundColor Red
}

# Disconnect from Microsoft Graph
Write-Log "Disconnecting from Microsoft Graph API..."
Disconnect-MgGraph
Write-Log "Script completed!"