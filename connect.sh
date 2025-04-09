#!/bin/bash

# Cek argumen
if [ -z "$1" ]; then
  echo "❌  Usage: $0 <public-ip>"
  echo "📌  Example: $0 13.229.123.45"
  exit 1
fi

# Path ke private key
KEY_PATH=~/.ssh/poc-mcp

# SSH ke server
echo "🔐 Connecting to ec2-user@$1 using key $KEY_PATH..."
ssh -i "$KEY_PATH" ec2-user@"$1"
