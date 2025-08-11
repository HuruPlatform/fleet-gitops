#!/bin/bash
USERNAME="hurubackupadmin"
FULLNAME="backup admin"
PASSWORD="Hurubackup@admin123"

sudo sysadminctl -addUser "$USERNAME" -fullName "$FULLNAME" -password "$PASSWORD"
sudo dseditgroup -o edit -a "$USERNAME" -t user admin
