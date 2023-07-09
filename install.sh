#!/bin/bash
#
NAME=git-sync
APP_NAME=$NAME.sh
BIN_DIR=/usr/bin
CONFIG_DIR=/etc/$NAME.d
SYSTEMD_LIB_DIR=/lib/systemd/system
SYSTEMD_DIR=/etc/systemd/system

echo "Copy script:"
cp $APP_NAME $BIN_DIR/$APP_NAME

echo "Copy config:"
mkdir $CONFIG_DIR
cp config.json $CONFIG_DIR/config.json
cp repos $CONFIG_DIR/repos

echo "Init service:"
cp $NAME.service $SYSTEMD_LIB_DIR/$NAME.service
ln -sf $SYSTEMD_LIB_DIR/$NAME.service $SYSTEMD_DIR/$NAME.service

echo "Init timer:"
cp $NAME.timer $SYSTEMD_LIB_DIR/$NAME.timer
ln -sf $SYSTEMD_LIB_DIR/$NAME.timer $SYSTEMD_DIR/$NAME.timer

systemctl daemon-reload 
systemctl --now enable $NAME.timer
