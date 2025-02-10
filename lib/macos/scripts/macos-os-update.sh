## Organisation info
org="Huru Payments"
org_contact="itsupport@huru.co"
# List of current users
users_list=$(dscacheutil -q user | grep -A 3 -B 2 -e uid:\ 5'[0-9][0-9]' | grep name | cut -d' ' -f2)
## Messages 
################################################
# 1.1 Verify all Apple-provided software is current
################################################
#print_info "Check for system updates"
#updates=$(softwareupdate -l 2>&1 | grep "No new software available.")

#if [[ $updates =~ "No new software"* ]]; then
#    echo  "No software updates available\n"
#else 
#    echo "System updates are available\n"
#    nohup sudo softwareupdate -i -a > /tmp/output.txt 2> /tmp/error.txt >/dev/null &
#
#fi
sudo softwareupdate -i -a -R