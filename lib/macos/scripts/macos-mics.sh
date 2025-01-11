## Organisation info
org="Huru Payments"
org_contact="itsupport@huru.co"
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