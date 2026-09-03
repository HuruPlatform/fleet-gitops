#!/bin/zsh
#
# CIS remediation, user scope. Run as root (Fleet runs scripts as root), but every
# setting below lives in a per-user preference file, so each write is executed as
# the owning user via `launchctl asuser` -- a plain `defaults write` as root lands
# in root's own preferences and the policy keeps failing.
#
# These keys CANNOT be set by a configuration profile: the policy queries read
# /Users/<name>/Library/Preferences/..., while a profile writes to
# /Library/Managed Preferences/. That is why they stayed red after every profile
# in default.yml was verified.
#
# Idempotent. Companion: macos-cis-remediate-system.sh for root-owned state.

set -u
LOG() { echo "[cis-user] $*"; }

# Real, non-system local accounts with a home under /Users.
USERS=$(/usr/bin/dscl . -list /Users UniqueID | /usr/bin/awk '$2 >= 500 {print $1}')

if [ -z "$USERS" ]; then
  LOG "no local users with UID >= 500; nothing to do"
  exit 0
fi

for U in ${(f)USERS}; do
  HOME_DIR=$(/usr/bin/dscl . -read "/Users/$U" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')
  case "$HOME_DIR" in
    /Users/*) ;;
    *) continue ;;
  esac
  [ -d "$HOME_DIR" ] || continue

  UID_N=$(/usr/bin/id -u "$U" 2>/dev/null) || continue
  LOG "remediating $U (uid $UID_N)"

  # asuser puts the write in the user's own preference domain and keeps cfprefsd
  # in sync, so the change is visible without a logout.
  AS_USER="/bin/launchctl asuser $UID_N /usr/bin/sudo -u $U"

  # --- Siri ------------------------------------------------------------------
  # Policies want LockscreenEnabled, StatusMenuVisible and TypeToSiriEnabled
  # all false in ~/Library/Preferences/com.apple.Siri.plist.
  eval $AS_USER /usr/bin/defaults write com.apple.Siri LockscreenEnabled      -bool false
  eval $AS_USER /usr/bin/defaults write com.apple.Siri StatusMenuVisible       -bool false
  eval $AS_USER /usr/bin/defaults write com.apple.Siri TypeToSiriEnabled       -bool false
  eval $AS_USER /usr/bin/defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false

  # --- Show all filename extensions -----------------------------------------
  # Query reads AppleShowAllExtensions from the user's .GlobalPreferences.plist.
  eval $AS_USER /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # --- Safari advertising privacy (needs Full Disk Access for fleetd) --------
  # Safari's prefs are inside a sandboxed container; without FDA the write is
  # silently refused, which is why the policy is tagged "FDA Required".
  SAFARI_PLIST="$HOME_DIR/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari"
  if [ -f "$SAFARI_PLIST.plist" ]; then
    eval $AS_USER /usr/bin/defaults write "$SAFARI_PLIST" \
      WebKitPreferences.privateClickMeasurementEnabled -bool true
    # Hide IP address. The query tests ((value >> 2) & 1) = 1, i.e. bit 2 must be
    # set. 33422 satisfies that; the 130272 used by the older ad-hoc script in
    # this repo does NOT (bit 2 clear), which is why that check kept failing.
    eval $AS_USER /usr/bin/defaults write "$SAFARI_PLIST" \
      WBSPrivacyProxyAvailabilityTraffic -int 33422
  else
    LOG "  Safari prefs not present for $U (Safari never launched); skipping"
  fi
done

# --- Show location icon in Control Center -------------------------------------
# This one is system scope despite appearing in the user-facing UI: the query
# reads /Library/Preferences/com.apple.locationmenu.plist, so it is a root write.
LOG "enabling location icon for system services"
/usr/bin/defaults write /Library/Preferences/com.apple.locationmenu ShowSystemServices -bool true
/bin/chmod 0644 /Library/Preferences/com.apple.locationmenu.plist 2>/dev/null

# --- Flush the preferences cache ---------------------------------------------
# MUST be last. cfprefsd holds every domain written above in memory and hands the
# stale copy to osquery, so a correct plist on disk still reads as non-compliant.
# launchd restarts it immediately.
LOG "flushing preferences cache so osquery sees the new values"
/usr/bin/killall cfprefsd 2>/dev/null

LOG "done"
exit 0
