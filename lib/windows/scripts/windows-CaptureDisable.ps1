$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\TabletPC"
$regPath2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Create the key if it doesn't exist
if (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force
}

# Set the DisableSnippingTool value
New-ItemProperty -Path $regPath -Name "DisableSnippingTool" -Value 1 -PropertyType DWORD -Force
# Set the DisableSnippingTool value to 0 to enable Snipping Tool

New-ItemProperty -Path $regPath2  -Name "DisabledHotkeys"  -PropertyType String -Value "S" -Force

#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisabledHotkeys" -ErrorAction SilentlyContinue

