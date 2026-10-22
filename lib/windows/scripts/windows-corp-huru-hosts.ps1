# Add a hosts entry for corp.huru.co pointing at the NEW forest's domain
# controllers in shared-eu, and flush the resolver cache.
#
# WHY THIS EXISTS. The FortiClient dialup VPN pushes DNS 8.8.8.8 and
# 10.1.114.106. The first is public and answers NXDOMAIN for corp.huru.co; the
# second is the old forest's second DC, Impaired since 2026-03-02. The name
# resolves nowhere for VPN users.
#
# READ THIS BEFORE DEPLOYING IT TO WINDOWS MACHINES.
#
# A hosts file maps names to addresses and cannot hold SRV records, which is
# what Active Directory uses to find a domain controller:
#     _ldap._tcp.dc._msdcs.corp.huru.co    SRV 389
#     _kerberos._tcp.corp.huru.co          SRV 88
#
# On a Windows machine that is about to be domain-joined, that combination is
# actively unhelpful: corp.huru.co resolves, so the name looks fine, while the
# DC locator still fails - and the resulting join errors point nowhere near DNS.
# Do NOT deploy this to machines queued for migration with
# Migrate-DomainJoin.ps1. That script repoints the resolvers properly in Phase
# 1, which is the correct mechanism.
#
# It is reasonable on a Windows machine that only needs to REACH a DC by name
# (a share, an admin tool) and is not joining the domain.
#
# The real fix is one line in terraform/network/fortigate-aws/fclient-dialup.tf:
# set ipv4_dns_server1/2 to these two addresses.
#
# Idempotent. Every line carries the marker below, so removal is exact. Set
# HURU_REMOVE=1 to undo. Fleet runs scripts as SYSTEM, so no elevation step.

$ErrorActionPreference = 'Stop'

$Marker = '# huru-ad-migration'
$DC1    = '10.3.27.35'
$DC2    = '10.3.115.131'

# Set HURU_REMOVE=1 in the environment to undo instead of apply.
$Remove = ($env:HURU_REMOVE -eq '1')

# HURU_HOSTS_FILE exists so this can be exercised against a throwaway file
# before it is pointed at the real one. Unset - which is how Fleet runs it - it
# is the real hosts file.
$HostsFile = if ($env:HURU_HOSTS_FILE) { $env:HURU_HOSTS_FILE }
             else { Join-Path $env:SystemRoot 'System32\drivers\etc\hosts' }

$want = @(
    "$DC1`tcorp.huru.co $Marker"
    "$DC2`tcorp.huru.co $Marker"
    "$DC1`tip-c61301f7.corp.huru.co $Marker"
    "$DC2`tip-c6130242.corp.huru.co $Marker"
)

if (-not (Test-Path -LiteralPath $HostsFile)) {
    throw "hosts file not found at $HostsFile"
}

# -Encoding ASCII throughout. The hosts file must stay ASCII/ANSI: writing it as
# UTF-8 with a BOM makes the Windows resolver ignore the FIRST entry, which is a
# silent and very confusing failure.
$existing = @(Get-Content -LiteralPath $HostsFile -Encoding ASCII)
$ours     = @($existing | Where-Object { $_ -like "*$Marker*" })
$others   = @($existing | Where-Object { $_ -notlike "*$Marker*" })

if ($Remove) {
    if ($ours.Count -eq 0) { Write-Output 'nothing to remove'; exit 0 }
    Set-Content -LiteralPath $HostsFile -Value $others -Encoding ASCII
    if (-not $env:HURU_HOSTS_FILE) { & ipconfig /flushdns | Out-Null }
    Write-Output "removed $($ours.Count) corp.huru.co hosts entries"
    exit 0
}

if (($ours -join "`n") -eq ($want -join "`n")) {
    Write-Output 'corp.huru.co hosts entries already correct - no change'
    exit 0
}

# Rewrite rather than append, so a changed DC address replaces the old line
# instead of leaving two entries for one name.
Set-Content -LiteralPath $HostsFile -Value ($others + $want) -Encoding ASCII
if (-not $env:HURU_HOSTS_FILE) { & ipconfig /flushdns | Out-Null }

Write-Output "corp.huru.co -> $DC1, $DC2"

# Show what the resolver returns now. Not fatal if the tunnel is down.
try {
    $r = Resolve-DnsName -Name corp.huru.co -Type A -ErrorAction Stop
    ($r | Where-Object { $_.IPAddress } | ForEach-Object { "  resolves to $($_.IPAddress)" }) -join "`n"
} catch {
    Write-Output '  note: lookup returned nothing - is the VPN connected?'
}
