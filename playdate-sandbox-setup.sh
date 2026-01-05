#!/usr/bin/env bash
# Playdate SDK Sandbox Setup Script
# This script ensures PlaydateSimulator has a writable environment

PLAYDATE_SDK_DIR=".PlaydateSDK"
SANDBOX_DIR="$(pwd)/$PLAYDATE_SDK_DIR"

if [ ! -d "$SANDBOX_DIR" ]; then
  echo "PlaydateSimulator: No local .PlaydateSDK found."
  read -p "Create .PlaydateSDK in $(pwd)? [y/n]: " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "PlaydateSimulator: Cancelled"
    exit 1
  fi

  echo "PlaydateSimulator: Creating sandbox at $SANDBOX_DIR"
  mkdir -p "$SANDBOX_DIR"
  cp -r @PLAYDATE_SDK@/Disk "$SANDBOX_DIR/Disk"
  chmod -R 755 "$SANDBOX_DIR/Disk"
  ln -s @PLAYDATE_SDK@/bin "$SANDBOX_DIR/bin"
  ln -s @PLAYDATE_SDK@/C_API "$SANDBOX_DIR/C_API"
  ln -s @PLAYDATE_SDK@/CoreLibs "$SANDBOX_DIR/CoreLibs"
  ln -s @PLAYDATE_SDK@/Examples "$SANDBOX_DIR/Examples"
  ln -s @PLAYDATE_SDK@/Resources "$SANDBOX_DIR/Resources"
fi

echo "PlaydateSimulator: Using sandbox at $SANDBOX_DIR"

# Set the PLAYDATE_SDK_PATH
# This seems redundant, but it's not guaranteed to be set
# For whatever reason, PlaydateSimulator doesn't like absolute paths -- go figure
export PLAYDATE_SDK_PATH="$PLAYDATE_SDK_DIR"