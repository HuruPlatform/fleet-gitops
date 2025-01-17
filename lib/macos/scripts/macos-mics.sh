## Organisation info
org="Huru Payments"
org_contact="itsupport@huru.co"
# List of current users
users_list=$(dscacheutil -q user | grep -A 3 -B 2 -e uid:\ 5'[0-9][0-9]' | grep name | cut -d' ' -f2)
## Messages 
login_screen_msg="If you found this laptop please let $org know at $org_contact. A rewards will be provided.\nSi vous trouvez cet ordinateur, veuillez s'il vous plait contacter $org à $org_contact. Une récomponse sera attribuée."
login_window_banner="* * * * * * * * * * W A R N I N G * * * * * * * * * *
UNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED
You must have explicit, authorized permission to access or configure this device. Unauthorized attempts and actions to access or use this system may result in civil and/or criminal penalties. All activities performed on this device are logged and monitored
* * * * * * * * * * * * * * * * * * * * * * * *"
################################################
# 1.2 Enable Auto Update
################################################
#print_info "Enable automatic updates"
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -int true
################################################
# 5.13 Create a custom message for the Login Screen
################################################ 
#print_info "Add login screen message: $login_screen_msg"
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$login_screen_msg"
################################################
# 5.14 Create a Login window banner
################################################
#print_info "Add login window banner"
echo "$login_window_banner" | sudo tee /Library/Security/PolicyBanner.txt
sudo chmod 644 "/Library/Security/PolicyBanner."*  2> /dev/null
################################################
# 2.5.6 Limit Ad tracking and personalized Ads
################################################
#print_info "Limit Ad tracking and personalized Ads"
for user in $users_list; do
    sudo -u "$user" defaults -currentHost write /Users/"$user"/Library/Preferences/com.apple.Adlib.plist allowApplePersonalizedAdvertising -bool false 2> /dev/null
done
################################################
# 5.12 Ensure an administrator account cannot login to another user's active and locked session
################################################
#print_info "Ensure an administrator account cannot login to another user's active and locked session"
sudo security authorizationdb write system.login.screensaver use-login-window-ui
#sudo security authorizationdb write system.login.screensaver authenticate-session-owner
################################################
# 5.2.6 Complex passwords must contain uppercase and lowercase letters
###############################################
#print_info "Set password policy: must contain uppercase and lowercase letters"
sudo pwpolicy -n /Local/Default -setglobalpolicy "requiresMixedCase=1"
################################################
# 5.1.1 Secure Home Folders 
################################################
#print_info "Securing home folders"
for user in $users_list; do
    sudo chmod -R og-rwx /Users/"$user" 2> /dev/null
done
################################################
# 3.3 Retain install.log for 365 or more days with no maximum sizes
################################################
#print_info "Retain install.log for 365 days"
sudo sed -i.bu '$s/$/ ttl=365/' /etc/asl/com.apple.install
#print_info "Set maximum size to 1G"
#sudo sed -i.bu 's/all_max=[0-9]*[mMgG]/all_max=1G/g' /etc/asl/com.apple.install
sudo sed -i.bu 's/all_max=[0-9]*[mMgG]//g' /etc/asl/com.apple.install
################################################
# 2.9 Disable Power Nap
################################################
#print_info "Disable Power Nap"
sudo pmset -a powernap 0
################################################
# 2.8 Disable Wake for network access 
################################################
#print_info "Disable Wake for network access"
sudo pmset -a womp 0 2> /dev/null 
################################################
# 3.1 Enable security auditing 
################################################
#print_info "Enable security auditing "
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist 2> /dev/null
sudo cp /etc/security/audit_control.example /etc/security/audit_control
################################################
# 3.2 Configure Security Auditing Flags per local organizational requirements
################################################
#print_info "Set auditing flags to 'all'"
sudo sed -i.bu "s/^flags:.*/flags:-all/g" /etc/security/audit_control 2> /dev/null 
sudo sed -i.bu "/^flags/ s/$/,lo,ad,aa/" /etc/security/audit_control 2> /dev/null
################################################
# 3.4 Ensure security auditing retention
################################################
#print_info "Set audit records expiration to 1 gigabyte"
sudo sed -i.bu "s/^expire-after:.*/expire-after:60d OR 5G/g" /etc/security/audit_control
################################################
# 6.2 Turn on filename extensions
################################################
#print_info "Turn on filename extensions"
for user in $users_list; do
    sudo -u "$user" defaults write /Users/"$user"/Library/Preferences/.GlobalPreferences.plist AppleShowAllExtensions -bool true
done
################################################
# 3.5 Control access to audit records
################################################
#print_info "Set the audit records to the root user and wheel group"
#sudo chown -R root:wheel /etc/security/audit_control 2> /dev/null
#sudo chmod -R 400 /etc/security/audit_control 2> /dev/null
#sudo chown -R root:wheel /var/audit/ 2> /dev/null
#sudo chmod -R 440 /var/audit/ 2> /dev/null
################################################
# 4.2 Enable "Show Wi-Fi/Bluetooth status in menu bar"
################################################
#print_info "Enable 'Show Wi-Fi/Bluetooth status in menu bar' for all users" 
for user in $users_list; do
    sudo -u "$user" defaults -currentHost write com.apple.controlcenter.plist WiFi -int 18
    sudo -u "$user" defaults -currentHost write com.apple.controlcenter.plist Bluetooth -int 18
done
################################################
# 4.00 Ensure Logging Is Enabled for Sudo"
################################################
sudo sed -i '' '/log_allowed/s|^|#|' /etc/sudoers
################################################
# 4.2 Enable "Advertising Privacy Protection in Safari Is Enabled"
################################################
#print_info "Ensure Advertising Privacy Protection in Safari Is Enabled' for all users" 
for user in $users_list; do
    sudo -u "$user" defaults write /Users/"$user"/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WebKitPreferences.privateClickMeasurementEnabled -bool true
done

################################################
# 4.2 Enable "Hide IP Address in Safari is Enabled"
################################################
#print_info "Hide IP Address in Safari is Enabled' for all users" 
for user in $users_list; do
    sudo -u "$user" defaults write /Users/"$user"/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WBSPrivacyProxyAvailabilityTraffic -int 130276
done
################################################
# 5.1.3 Check System folder for world writable files
################################################
#/usr/bin/sudo IFS=$'\n'
for sysPermissions in $( find /System/Volumes/Data/System -type d -perm -2 | grep -vE "Drop Box|locks|downloadDir" ); 
do
  chmod -R o-w "$sysPermissions"
done
################################################
# 5.1.4 Check Library folder for world writable files
################################################
#/usr/bin/sudo IFS=$'\n'
for libPermissions in $( find /System/Volumes/Data/Library -type d -perm -2 | grep -v Caches | grep -v /Preferences/Audio/Data); 
do
  chmod -R o-w "$libPermissions"
done
################################################
# 5.10 Ensure system is set to hibernate
################################################
#print_info "Set the hibernate delays and to ensure the FileVault keys are set to be destroyed on standby"
if [[ $(uname -m) == 'arm64' ]]; then
        # Apple silicon
        sudo pmset -a standby 900
        sudo pmset -a destroyfvkeyonstandby 1
else
        # Intel
        sudo pmset -a standbydelaylow 900
        sudo pmset -a standbydelayhigh 900
        sudo pmset -a highstandbythreshold 90
        sudo pmset -a destroyfvkeyonstandby 1
        sudo pmset -a hibernatemode 25
fi
################################################
# 2.13 Review Siri Settings
################################################
#print_info "Disable Siri"
for user in $users_list; do
    sudo -u "$user" defaults write com.apple.assistant.support.plist 'Assistant Enabled' -bool false 2> /dev/null
    sudo -u "$user" defaults write com.apple.Siri.plist LockscreenEnabled -bool false 2> /dev/null
    sudo -u "$user" defaults write com.apple.Siri.plist StatusMenuVisible -bool false 2> /dev/null
    sudo -u "$user" defaults write com.apple.Siri.plist VoiceTriggerUserEnabled -bool false 2> /dev/null
done