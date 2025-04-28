$zipSource = "\\corp.huru.co\SYSVOL\corp.huru.co\scripts\PolicyDefinitions.zip"
$tempPath = "$env:TEMP\PolicyDefinitions"
$destinationPath = "C:\Windows\PolicyDefinitions"

# Create temp folder
if (Test-Path $tempPath) {
    Remove-Item -Path $tempPath -Recurse -Force
}
New-Item -Path $tempPath -ItemType Directory | Out-Null

# Copy zip to temp
Copy-Item -Path $zipSource -Destination "$tempPath\PolicyDefinitions.zip" -Force

# Extract
Expand-Archive -Path "$tempPath\PolicyDefinitions.zip" -DestinationPath $destinationPath -Force

# Clean up
Remove-Item -Path $tempPath -Recurse -Force
