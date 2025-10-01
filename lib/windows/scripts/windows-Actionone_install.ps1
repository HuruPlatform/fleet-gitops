# Define variables
$TempPath = "C:\Temp"
$MSIName = "action1_agent.msi"
$MSIPath = Join-Path $TempPath $MSIName
$DownloadURL = "https://app.eu.action1.com/agent/fe1a0084-996c-11f0-b5f9-2762f9216329/Windows/agent(Huru).msi"

# Create temp directory if it doesn't exist
if (-not (Test-Path $TempPath)) {
    New-Item -Path $TempPath -ItemType Directory | Out-Null
}

# Download the MSI
Invoke-WebRequest -Uri $DownloadURL -OutFile $MSIPath

# Install the MSI silently
Start-Process msiexec.exe -ArgumentList "/i `"$MSIPath`" /quiet /qn /norestart" -Wait

Write-Output "Action1 agent installed successfully."
