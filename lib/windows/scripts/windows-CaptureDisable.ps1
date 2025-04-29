$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\TabletPC"

# Create the key if it doesn't exist
if (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force
}

# Set the DisableSnippingTool value
New-ItemProperty -Path $regPath -Name "DisableSnippingTool" -Value 1 -PropertyType DWORD -Force

Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.ScreenSketch"} | Remove-AppxProvisionedPackage -Online
Get-AppxPackage *ScreenSketch* | Remove-AppxPackage
