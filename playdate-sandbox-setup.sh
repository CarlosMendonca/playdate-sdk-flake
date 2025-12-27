#!/usr/bin/env bash
# Playdate SDK Sandbox Setup Script
# This script ensures PlaydateSimulator has a writable environment

# Determine sandbox location
SANDBOX_DIR=""
XDG_FALLBACK="${XDG_DATA_HOME:-$HOME/.local/share}/PlaydateSDK"

if [ -d ".PlaydateSDK" ]; then
  SANDBOX_DIR="$(pwd)/.PlaydateSDK"
else
  # No local sandbox, ask user where they want it
  echo "PlaydateSimulator: No local .PlaydateSDK found."
  echo "  [1] Create in current directory: $(pwd)/.PlaydateSDK"
  echo "  [2] Use XDG data directory: $XDG_FALLBACK"
  read -p "Choose [1/2] or cancel [n]: " -n 1 -r
  echo

  if [[ $REPLY =~ ^[1]$ ]]; then
    SANDBOX_DIR="$(pwd)/.PlaydateSDK"
  elif [[ $REPLY =~ ^[2]$ ]]; then
    SANDBOX_DIR="$XDG_FALLBACK"
  else
    echo "PlaydateSimulator: Cancelled"
    exit 1
  fi

  # Create sandbox if it doesn't exist
  if [ ! -d "$SANDBOX_DIR" ]; then
    echo "PlaydateSimulator: Creating sandbox at $SANDBOX_DIR"
    mkdir -p "$SANDBOX_DIR"
    cp -TR @PLAYDATE_SDK@/Disk "$SANDBOX_DIR/Disk"
    chmod -R 755 "$SANDBOX_DIR/Disk"
    ln -s @PLAYDATE_SDK@/bin "$SANDBOX_DIR/bin"
    ln -s @PLAYDATE_SDK@/C_API "$SANDBOX_DIR/C_API"
    ln -s @PLAYDATE_SDK@/CoreLibs "$SANDBOX_DIR/CoreLibs"
    ln -s @PLAYDATE_SDK@/Resources "$SANDBOX_DIR/Resources"
  fi
fi

echo "PlaydateSimulator: Using sandbox at $SANDBOX_DIR"
export PLAYDATE_SDK_PATH="$SANDBOX_DIR"
