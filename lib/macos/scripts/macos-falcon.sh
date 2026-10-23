#!/bin/bash

CUSTOMER_ID="90D12E1CD1CD4AB8AAF14B8AE284AC39-FA"

FALCON_PATH="/Applications/Falcon.app/Contents/Resources/falconctl"

sudo "$FALCON_PATH" license "$CUSTOMER_ID"

# Check status
if [ $? -eq 0 ]; then
    echo "Activation completed"
else
    echo "Activation failed"
    exit 1
fi
