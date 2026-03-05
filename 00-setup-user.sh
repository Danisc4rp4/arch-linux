#!/bin/bash

# This is the first script, it is ran as root
# input1 = username

# If the script is ised with more then one arguments, then print out usage and exit.
if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

NEW_USER=$1
SSH_FOLDER=/home/$NEW_USER/.ssh

mkdir -p $SSH_FOLDER
cp /root/.ssh/* $SSH_FOLDER
chown -R "$NEW_USER:$NEW_USER" $SSH_FOLDER
