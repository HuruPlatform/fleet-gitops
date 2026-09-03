#!/bin/zsh
#
# CIS remediation, system scope. Run as root (Fleet runs scripts as root).
#
# Each block targets one CIS policy in lib/macos/policies/macos-cis.policies.yml
# that a configuration profile CANNOT satisfy, because the policy query reads live
# system state (/etc/..., pmset, authdb) rather than /Library/Managed Preferences.
#
# The literal strings here are load-bearing: they are matched by the policy queries.
# "expire-after:60d OR 5G" must keep the " OR " because the query regex is
# 'expire-after:(\d+)d OR (\d+)G'. A stricter value in a different format fails.
#
# Idempotent. Companion: macos-cis-remediate-user.sh for per-user keys.

set -u
LOG() { echo "[cis-system] $*"; }

# --- Guest access to shared folders -----------------------------------------
LOG "disabling SMB guest access"
/usr/sbin/sysadminctl -smbGuestAccess off 2>/dev/null
/usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server \
  AllowGuestAccess -bool false

# --- Power management --------------------------------------------------------
# Power Nap and Wake-for-network both need the value clear on AC *and* Battery,
# hence -a. DestroyFVKeyOnStandby plus the standby/hibernate values satisfy
# "OS is not Activate When Resuming from Sleep".
LOG "applying power management settings"
/usr/bin/pmset -a powernap 0                2>/dev/null
/usr/bin/pmset -a womp 0                    2>/dev/null
/usr/bin/pmset -a destroyfvkeyonstandby 1   2>/dev/null
/usr/bin/pmset -a hibernatemode 25          2>/dev/null
/usr/bin/pmset -a standbydelaylow 900       2>/dev/null
/usr/bin/pmset -a standbydelayhigh 900      2>/dev/null
/usr/bin/pmset -a highstandbythreshold 90   2>/dev/null

# --- Login window banner -----------------------------------------------------
LOG "installing login window banner"
if [ ! -f /Library/Security/PolicyBanner.txt ]; then
  /usr/bin/printf '%s\n' \
    'This system is the property of Huru and is for authorised use only.' \
    'Activity may be monitored and reported. Disconnect now if you are not an authorised user.' \
    > /Library/Security/PolicyBanner.txt
fi
/usr/sbin/chown root:wheel /Library/Security/PolicyBanner.txt
/bin/chmod 0644 /Library/Security/PolicyBanner.txt

# --- Password hint -----------------------------------------------------------
# Query: user_login_settings.password_hint_enabled = 0.
LOG "disabling password hints"
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0

# --- Sudo timeout ------------------------------------------------------------
# Query requires /etc/sudoers.d owned root:wheel AND a zero timestamp timeout.
# A drop-in file is used deliberately: /etc/sudoers itself is never edited here,
# because a malformed sudoers locks every account out of sudo.
LOG "setting sudo timeout to zero"
/bin/mkdir -p /etc/sudoers.d
/usr/sbin/chown root:wheel /etc/sudoers.d
/bin/chmod 0755 /etc/sudoers.d
SUDO_DROPIN=/etc/sudoers.d/cis_sudo_timeout
echo 'Defaults timestamp_timeout=0' > "$SUDO_DROPIN.new"
/usr/sbin/chown root:wheel "$SUDO_DROPIN.new"
/bin/chmod 0440 "$SUDO_DROPIN.new"
# Validate before putting it in place; a bad file here breaks sudo system-wide.
if /usr/sbin/visudo -cf "$SUDO_DROPIN.new" >/dev/null 2>&1; then
  /bin/mv -f "$SUDO_DROPIN.new" "$SUDO_DROPIN"
else
  LOG "  visudo rejected the drop-in; leaving sudoers untouched"
  /bin/rm -f "$SUDO_DROPIN.new"
fi

# --- install.log retention ---------------------------------------------------
# Needs a line with ttl>=365 AND no line containing "all_max=" anywhere.
LOG "setting install.log retention to 365 days"
if [ -f /etc/asl/com.apple.install ]; then
  /usr/bin/sed -i '' -E 's/[[:space:]]*all_max=[^[:space:]]*//g' /etc/asl/com.apple.install
  if /usr/bin/grep -qE 'ttl=[0-9]+' /etc/asl/com.apple.install; then
    /usr/bin/sed -i '' -E 's/ttl=[0-9]+/ttl=365/g' /etc/asl/com.apple.install
  else
    /usr/bin/sed -i '' -E 's|(^\*[[:space:]]+file[[:space:]]+/var/log/install\.log.*)$|\1 ttl=365|' \
      /etc/asl/com.apple.install
  fi
fi

# --- Security auditing -------------------------------------------------------
# macOS 15+ ships NO /etc/security/audit_control, only audit_control.example.
# An earlier version of this script guarded on [ -f audit_control ] and therefore
# silently skipped all three audit policies. Seed it from the example instead.
AUDIT_CONTROL=/etc/security/audit_control
LOG "configuring security auditing"
if [ ! -f "$AUDIT_CONTROL" ]; then
  if [ -f "$AUDIT_CONTROL.example" ]; then
    LOG "  audit_control absent; seeding from audit_control.example"
    /bin/cp "$AUDIT_CONTROL.example" "$AUDIT_CONTROL"
  else
    LOG "  audit_control absent and no example present; writing a minimal file"
    /usr/bin/printf '%s\n' \
      'dir:/var/audit' \
      'flags:lo,aa' \
      'minfree:5' \
      'naflags:lo,aa' \
      'policy:cnt,argv' \
      'filesz:2M' \
      'expire-after:60d OR 5G' \
      > "$AUDIT_CONTROL"
  fi
fi

if [ -f "$AUDIT_CONTROL" ]; then
  # Flags must match the query's first pattern: -fm, ad, -ex, aa, -fr, lo, -fw.
  if /usr/bin/grep -q '^flags:' "$AUDIT_CONTROL"; then
    /usr/bin/sed -i '' -E 's/^flags:.*/flags:-fm,ad,-ex,aa,-fr,lo,-fw/' "$AUDIT_CONTROL"
  else
    echo 'flags:-fm,ad,-ex,aa,-fr,lo,-fw' >> "$AUDIT_CONTROL"
  fi

  # Retention: days >= 60 and size >= 5, in the exact " OR " form.
  if /usr/bin/grep -q '^expire-after:' "$AUDIT_CONTROL"; then
    /usr/bin/sed -i '' -E 's/^expire-after:.*/expire-after:60d OR 5G/' "$AUDIT_CONTROL"
  else
    echo 'expire-after:60d OR 5G' >> "$AUDIT_CONTROL"
  fi

  /usr/sbin/chown root:wheel "$AUDIT_CONTROL"
  /bin/chmod 0400 "$AUDIT_CONTROL"
fi

# Query joins launchd against processes, so auditd must be loaded AND running.
LOG "enabling auditd"
/bin/mkdir -p /var/audit
/bin/launchctl enable system/com.apple.auditd 2>/dev/null
/bin/launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null
/bin/launchctl kickstart -k system/com.apple.auditd 2>/dev/null
/usr/sbin/audit -s 2>/dev/null

# --- Home folder permissions -------------------------------------------------
LOG "securing home folders"
for HOME_DIR in /Users/*(N/); do
  case "$HOME_DIR" in
    /Users/Shared|/Users/Shared/) continue ;;
    /Users/Guest|/Users/Guest/)   continue ;;
  esac
  /bin/chmod og-rwx "$HOME_DIR" 2>/dev/null
done

# --- World-writable directories ----------------------------------------------
# Two separate CIS policies, two separate trees, each with its own exclusions.
# Mirror the query exclusions exactly so we do not strip permissions the checks
# deliberately tolerate.
LOG "clearing world-writable bits under /System/Volumes/Data/System"
/usr/bin/find /System/Volumes/Data/System -type d -perm -0002 2>/dev/null \
  | /usr/bin/grep -v 'Drop Box' \
  | /usr/bin/grep -v 'locks' \
  | /usr/bin/grep -v 'downloadDir' \
  | while IFS= read -r DIR; do /bin/chmod o-w "$DIR" 2>/dev/null; done

LOG "clearing world-writable bits under /System/Volumes/Data/Library"
/usr/bin/find /System/Volumes/Data/Library -type d -perm -0002 2>/dev/null \
  | /usr/bin/grep -v 'Caches' \
  | /usr/bin/grep -v '/Preferences/Audio/Data' \
  | while IFS= read -r DIR; do /bin/chmod o-w "$DIR" 2>/dev/null; done

# --- Admin password required for system-wide preferences ---------------------
LOG "requiring admin password for system-wide preferences"
/usr/bin/security authorizationdb read system.preferences > /tmp/system.preferences.plist 2>/dev/null
if [ -s /tmp/system.preferences.plist ]; then
  /usr/bin/defaults write /tmp/system.preferences.plist shared -bool false
  /usr/bin/security authorizationdb write system.preferences < /tmp/system.preferences.plist 2>/dev/null
  /bin/rm -f /tmp/system.preferences.plist
fi

# --- Location Services -------------------------------------------------------
# CIS wants this ENABLED. locationd's preference store is SIP-protected on
# current macOS, so this is best effort and may legitimately stay red.
LOG "enabling Location Services (best effort)"
/bin/launchctl enable system/com.apple.locationd 2>/dev/null
/usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd \
  LocationServicesEnabled -int 1 2>/dev/null

LOG "done"
exit 0
