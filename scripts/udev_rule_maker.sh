#!/bin/bash

# bash script to make a udev rule for a USB serial device
# usage: ./setup_udev_rule.sh <arg1> <arg2>
# <arg1> is the port we want to make a link to (e.g ttyACM0)
# <arg2> is the virtual port that is linked to an actual link(e.g. ttyMyMicro)

# AI assistance was used to write a few of below lines

set -e

PORT_NAME=$1
SYMLINK_NAME=$2
USE_SERIAL=$3   # optional: "--serial"

# receving the arguments
if [[ -z "$PORT_NAME" || -z "$SYMLINK_NAME" ]]; then
    echo "Usage: $0 <device_port> <custom_name> [--serial]"
    echo "example: $0 ttyACM0 myArduino"
    exit 1
fi

DEVICE_PATH="/dev/$PORT_NAME"

# check for device
if [ ! -e "$DEVICE_PATH" ]; then
    echo "Device $DEVICE_PATH not found"
    exit 1
fi

# sanity check for symlink name (avoid weird udev rule names)
if [[ ! "$SYMLINK_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid symlink name. Use only letters, numbers, _ or -"
    exit 1
fi

echo "Target device: $DEVICE_PATH"

# optional permission fix (not always recommended, but kept as-is)
sudo chmod 666 "$DEVICE_PATH" || true

echo "getting device info for $DEVICE_PATH..."

udev_info=$(udevadm info --query=all --name="$DEVICE_PATH")

get_value() {
    echo "$udev_info" | grep -m1 "$1" | cut -d= -f2 || true
}

VENDOR_ID=$(get_value "ID_VENDOR_ID")
MODEL_ID=$(get_value "ID_MODEL_ID")
SERIAL=$(get_value "ID_SERIAL_SHORT")

if [[ -z "$VENDOR_ID" || -z "$MODEL_ID" ]]; then
    echo "couldn't extract USB IDs... is this a proper USB serial device?"
    exit 1
fi

echo "vendor:  $VENDOR_ID"
echo "product: $MODEL_ID"

if [[ "$USE_SERIAL" == "--serial" && -n "$SERIAL" ]]; then
    echo "serial:  $SERIAL"
fi

RULE_FILE="/etc/udev/rules.d/99-${SYMLINK_NAME}.rules"

# prevent accidental overwrite
if [[ -f "$RULE_FILE" ]]; then
    echo "rule already exists: $RULE_FILE"
    read -p "overwrite it? [y/N]: " ans
    if [[ "$ans" != "y" ]]; then
        echo "aborted"
        exit 0
    fi
fi

echo "writing rule to $RULE_FILE..."

if [[ "$USE_SERIAL" == "--serial" && -n "$SERIAL" ]]; then
    RULE_CONTENT="SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$MODEL_ID\", ATTRS{serial}==\"$SERIAL\", SYMLINK+=\"tty$SYMLINK_NAME\""
else
    RULE_CONTENT="SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$MODEL_ID\", SYMLINK+=\"tty$SYMLINK_NAME\""
fi

echo "$RULE_CONTENT" | sudo tee "$RULE_FILE" > /dev/null

echo "reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

sleep 1

LINK="/dev/tty$SYMLINK_NAME"

if [ -e "$LINK" ]; then
    echo "Success! symlink created: $LINK -> $PORT_NAME"
    ls -l "$LINK"
else
    echo "symlink not created. check rule or device info"
    echo "debug: try -> udevadm test $(udevadm info -q path -n $DEVICE_PATH)"
fi