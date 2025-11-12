#!/bin/bash

# Set the API token and channel ID
API_TOKEN="API_TOKEN"
CHANNEL_ID="CHANNEL_ID"

# Set the message text
MESSAGE="$1"

# Use curl to send the message
curl -s -X POST https://api.telegram.org/bot$API_TOKEN/sendMessage -d chat_id=$CHANNEL_ID -d text="$MESSAGE" > /dev/null