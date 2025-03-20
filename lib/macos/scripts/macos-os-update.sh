#!/bin/bash

LOG_FILE="/var/log/macos_update.log"
TIMER=300  # Time in seconds before restart (5 minutes)

echo "Starting macOS update process: $(date)" | tee -a "$LOG_FILE"

# Check for available updates
softwareupdate -l 2>&1 | tee -a "$LOG_FILE"

# Install all available updates
echo "Installing all available updates..." | tee -a "$LOG_FILE"
softwareupdate --install --all --agree-to-license 2>&1 | tee -a "$LOG_FILE"

# Check if update was successful
if [ $? -eq 0 ]; then
    echo "Updates installed successfully." | tee -a "$LOG_FILE"
    
    # Notify the user about restart
    osascript -e 'display dialog "Your Mac will restart in 5 minutes to complete updates. Please save your work." buttons {"OK"} default button "OK" with title "System Update"'

    # Wait before restart
    echo "Waiting $TIMER seconds before restart..." | tee -a "$LOG_FILE"
    sleep $TIMER

    # Force restart
    echo "Restarting now..." | tee -a "$LOG_FILE"
    shutdown -r now
else
    echo "Update failed. No restart." | tee -a "$LOG_FILE"
fi
