[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$email,
    [Parameter(Mandatory = $true)]
    [string]$password,
    [Parameter(Mandatory = $true)]
    [int]$scheduleId
)

# Define URLs
$baseUrl = "https://ais.usvisa-info.com/en-cr/niv"
$loginUrl = "$baseUrl/users/sign_in"
$appointmentUrl = "$baseUrl/schedule/$scheduleId/appointment"
$appointmentDaysUrl = "$baseUrl/schedule/$scheduleId/appointment/days/140.json?appointments[expedite]=false"

# Create a session object
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Initial GET to retrieve CSRF token
$initialResponse = Invoke-WebRequest -Uri $loginUrl -WebSession $session -Headers @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
}

$initialResponse.Content -match '<meta name="csrf-token" content="([^"]+)"' | Out-Null
$csrfToken = $matches[1]

# Login POST request
$loginBody = @{
    "user[email]"        = $email
    "user[password]"     = $password
    "policy_confirmed"   = "1"
    "commit"             = "Sign In"
}

$loginResponse = Invoke-WebRequest -Uri $loginUrl -Method POST -WebSession $session -Headers @{
    "User-Agent"         = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
    "X-CSRF-Token"       = $csrfToken
    "X-Requested-With"   = "XMLHttpRequest"
    "Referer"            = $loginUrl
    "Accept"             = "application/json, text/javascript, */*; q=0.01"
    "Content-Type"       = "application/x-www-form-urlencoded; charset=UTF-8"
} -Body $loginBody

Write-Host "Login response status code: $($loginResponse.StatusCode)"

# Appointment availability request
$appointmentResponse = Invoke-WebRequest -Uri $appointmentDaysUrl -WebSession $session -Headers @{
    "User-Agent"         = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
    "Accept"             = "application/json, text/javascript, */*; q=0.01"
    "Referer"            = $appointmentUrl
    "X-CSRF-Token"       = $csrfToken
    "X-Requested-With"   = "XMLHttpRequest"
    "Cache-Control"      = "no-cache"
    "Pragma"             = "no-cache"
}

Write-Host "Appointment dates response status code: $($appointmentResponse.StatusCode)"

# Define your preferred date range
$startDate = Get-Date "2026-01-15"
$endDate = Get-Date "2026-02-15"

# Parse and check available dates
try {
    $availableDates = $appointmentResponse.Content | ConvertFrom-Json

    if ($availableDates.Count -eq 0) {
        Write-Host "No available appointment dates found."
    } else {
        foreach ($entry in $availableDates) {
            $date = Get-Date $entry.date
            if ($date -ge $startDate -and $date -le $endDate) {
                Write-Host "Appointment available within range: $date"
                # Add notification logic here
            } else {
                Write-Host "Appointment available, but outside range: $date"
            }
        }
    }
} catch {
    Write-Host "Failed to retrieve or parse appointment dates: $_"
}