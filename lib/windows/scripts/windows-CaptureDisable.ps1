$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\TabletPC"
$regPath2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Create the key if it doesn't exist
if (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force
}
# Set the DisableSnippingTool value
New-ItemProperty -Path $regPath -Name "DisableSnippingTool" -Value 1 -PropertyType DWORD -Force
# Set the DisableSnippingTool value to 0 to enable Snipping Tool



# Create the registry path if it doesn't exist
#if (-not (Test-Path -Path $regPath2)) {
#    New-Item -Path $regPath2 -Force
#}
# Create or update the DisabledHotkeys value
#New-ItemProperty -Path $regPath2  -Name "DisabledHotkeys"  -PropertyType String -Value "S" -Force

#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisabledHotkeys" -ErrorAction SilentlyContinue


$users = Get-ChildItem -Path Registry::HKEY_USERS | Where-Object { $_.Name -match '^HKEY_USERS\\S+-\d+-\d+$' }

foreach ($user in $users) {
    $regPath = "$($user.Name)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    try {
        New-Item -Path "Registry::$regPath" -Force | Out-Null
        New-ItemProperty -Path "Registry::$regPath" -Name "DisabledHotkeys" -PropertyType String -Value "S" -Force
        Write-Host "Set DisabledHotkeys for $($user.Name)"
    } catch {
        Write-Warning "Failed to set key for $($user.Name): $_"
    }
}
