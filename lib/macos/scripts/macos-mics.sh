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