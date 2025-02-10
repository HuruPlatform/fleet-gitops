## Organisation info
org="Huru Payments"
org_contact="itsupport@huru.co"
# List of current users
users_list=$(dscacheutil -q user | grep -A 3 -B 2 -e uid:\ 5'[0-9][0-9]' | grep name | cut -d' ' -f2)
## Messages 
################################################
# 2.5.5 Disable sending diagnostic and usage data to Apple
################################################
#print_info "Disable sending diagnostic and usage data to Apple"
sudo defaults write /Library/"Application Support"/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false 2> /dev/null
sudo chmod 644 /Library/"Application Support"/CrashReporter/DiagnosticMessagesHistory.plist 2> /dev/null
sudo chgrp admin /Library/"Application Support"/CrashReporter/DiagnosticMessagesHistory.plist 2> /dev/null
################################################
# 2.4.12 Ensure AirDrop Is Disabled
################################################
#print_info "Disable AirDrop"
for user in $users_list; do
    sudo -u "$user" defaults write com.apple.NetworkBrowser DisableAirDrop -bool true 2> /dev/null
done