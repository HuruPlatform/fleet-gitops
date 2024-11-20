echo "Allowing guests to connect to shared folders enables users to access selected shared folders and their contents from different computers on a network"
/usr/bin/sudo /usr/sbin/sysadminctl -smbGuestAccess off
echo "Power Nap on the device:"
/usr/bin/sudo /usr/bin/pmset -a powernap 0
echo "Wake on  on the device:"
/usr/bin/sudo /usr/bin/pmset -a womp 0
echo "setting Sudo Timeout to zero"
echo 'Defaults timestamp_timeout=0' | sudo tee -a /etc/sudoers.d/CIS_54_sudoconfiguration
/usr/bin/sudo /usr/sbin/chown -R root:wheel /etc/sudoers.d/
echo "Hide IP Address in Safari"
/usr/bin/sudo -u  /usr/bin/defaults write /Users//Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WBSPrivacyProxyAvailabilityTraffic -int 130272
