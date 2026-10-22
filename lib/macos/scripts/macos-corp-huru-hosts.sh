#!/bin/sh
# Add a /etc/hosts entry for corp.huru.co pointing at the NEW forest's domain
# controllers in shared-eu, and flush the resolver cache.
#
# WHY THIS EXISTS. The FortiClient dialup VPN pushes DNS servers 8.8.8.8 and
# 10.1.114.106. The first is public and answers NXDOMAIN for corp.huru.co; the
# second is the old forest's second DC, Impaired since 2026-03-02. So the name
# resolves nowhere for VPN users.
#
# THIS IS A STOPGAP, NOT THE FIX. A hosts file maps names to addresses and
# nothing else - it cannot hold the SRV records AD actually uses to locate a
# domain controller (_ldap._tcp.dc._msdcs.corp.huru.co and friends). This makes
# `ping corp.huru.co` work and lets you reach a DC by name. It does not make
# domain logon, Kerberos or DC location work.
#
# The real fix is one line in terraform/network/fortigate-aws/fclient-dialup.tf:
# set ipv4_dns_server1/2 to these two addresses. Once that is applied, REMOVE
# this script from the team and run it with REMOVE=1 to clean the hosts files.
#
# Idempotent: re-running changes nothing once the entries are correct. Every
# line it writes carries the marker below, so removal is exact and never
# touches anything else in /etc/hosts.
#
# Fleet runs scripts as root, so no sudo.

set -eu

MARKER="# huru-ad-migration"
HOSTS="/etc/hosts"
DC1="10.3.27.35"
DC2="10.3.115.131"

# Set REMOVE=1 in the Fleet script to undo instead of apply.
REMOVE="${REMOVE:-0}"

flush_dns() {
    dscacheutil -flushcache 2>/dev/null || true
    killall -HUP mDNSResponder 2>/dev/null || true
}

# Drop every line we own. grep -v returns 1 when nothing survives, so guard it.
strip_ours() {
    grep -v "$MARKER" "$HOSTS" > "$HOSTS.huru.tmp" 2>/dev/null || : > "$HOSTS.huru.tmp"
}

if [ "$REMOVE" = "1" ]; then
    if grep -q "$MARKER" "$HOSTS" 2>/dev/null; then
        strip_ours
        cat "$HOSTS.huru.tmp" > "$HOSTS"
        rm -f "$HOSTS.huru.tmp"
        flush_dns
        echo "removed corp.huru.co hosts entries"
    else
        echo "nothing to remove"
    fi
    exit 0
fi

# Already correct? Compare what we would write against what is there.
WANT="${DC1}	corp.huru.co ${MARKER}
${DC2}	corp.huru.co ${MARKER}
${DC1}	ip-c61301f7.corp.huru.co ${MARKER}
${DC2}	ip-c6130242.corp.huru.co ${MARKER}"

HAVE="$(grep "$MARKER" "$HOSTS" 2>/dev/null || true)"
if [ "$HAVE" = "$WANT" ]; then
    echo "corp.huru.co hosts entries already correct - no change"
    exit 0
fi

# Rewrite: strip our old lines (handles a changed DC address), then append.
# Written via a temp file and copied back so /etc/hosts is never truncated
# mid-write and keeps its original inode, owner and mode.
strip_ours
printf '%s\n' "$WANT" >> "$HOSTS.huru.tmp"
cat "$HOSTS.huru.tmp" > "$HOSTS"
rm -f "$HOSTS.huru.tmp"
flush_dns

echo "corp.huru.co -> ${DC1}, ${DC2}"
# Confirm resolution actually goes through the hosts file now. Not fatal if the
# tunnel happens to be down - the entry is still correct for next time.
if command -v dscacheutil >/dev/null 2>&1; then
    dscacheutil -q host -a name corp.huru.co 2>/dev/null | grep -E '^ip_address' || \
        echo "note: lookup returned nothing - is the VPN connected?"
fi
