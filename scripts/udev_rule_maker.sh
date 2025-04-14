#!/bin/bash

# bash script to make a udev rule for a USB serial device
# usage: ./setup_udev_rule.sh <arg1> <arg2>
# <arg1> is the port we want to make a link to (e.g ttyACM0)
# <arg2> is the virtual port that is linked to an actual link(e.g. ttyMyMicro)

# AI assistance was used to write a few of below lines

PORT_NAME=$1``
SYMLINK_NAME=$2

# receving the arguments
if [[ -z "$PORT_NAME" || -z "$SYMLINK_NAME" ]]; then
    echo "Usage: $0 <device_port> <custom_name>"
    echo "example: $0 ttyACM0 myArduino"
    exit 1
fi

DEVICE_PATH="/dev/$PORT_NAME"

#check for device
if [ ! -e "$DEVICE_PATH" ]; then
    echo "Device $DEVICE_PATH not found"
    exit 1
fi

#not necessary but I put it anyways
#echo "Setting permissions on $DEVICE_PATH..."
sudo chmod 666 "$DEVICE_PATH"
#echo "Done."

echo "getting device info for $DEVICE_PATH..."

# extract vendor id, product id, serial ID
# serial is used when two identical devices are connected. if so, uncomment line 50 and modify line 57
udev_info=$(udevadm info --query=all --name="$DEVICE_PATH")
VENDOR_ID=$(echo "$udev_info" | grep -m1 "ID_VENDOR_ID" | cut -d= -f2)
MODEL_ID=$(echo "$udev_info" | grep -m1 "ID_MODEL_ID" | cut -d= -f2)
SERIAL=$(echo "$udev_info" | grep -m1 "ID_SERIAL_SHORT" | cut -d= -f2)

if [[ -z "$VENDOR_ID" || -z "$MODEL_ID" ]]; then
    echo "couldn't extract USB IDs... is this a proper USB serial device?"
    exit 1
fi

echo "vendor: $VENDOR_ID"
echo "product: $MODEL_ID"
# I commented the line since there were sometimes I couldn't read serial number for some reason
# echo "serial: $SERIAL" 

# write rule file
RULE_FILE="/etc/udev/rules.d/99-${SYMLINK_NAME}.rules"
echo "writing rule to $RULE_FILE..."

sudo bash -c "cat > $RULE_FILE" <<EOF
SUBSYSTEM=="tty", ATTRS{idVendor}=="$VENDOR_ID", ATTRS{idProduct}=="$MODEL_ID", SYMLINK+="tty$SYMLINK_NAME"
EOF

# reload and apply
echo "reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

# small delay to give udev time
sleep 2

# check if symlink was created
if [ -e "/dev/tty$SYMLINK_NAME" ]; then
    echo "Succsess! symlink created: /dev/tty$SYMLINK_NAME -> $PORT_NAME"
    ls -l "/dev/tty$SYMLINK_NAME"
else
    echo "symlink not created. check the rule or device info again"
fi

# optional basic check - just to make sure device is alive
# echo "checking access to /dev/tty$SYMLINK_NAME..."
# if stat "/dev/tty$SYMLINK_NAME" > /dev/null 2>&1; then
#     echo "device is accessible"
# else
#     echo "device not accessible - maybe permissions?"
# fi
