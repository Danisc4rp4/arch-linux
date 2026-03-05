#!/bin/bash

# This is the first script, it is ran as root
# input1 = username

# If the script is ised with more then one arguments, then print out usage and exit.
if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

NEW_USER=$1

# Create the new user
# -m: create the home folder /home/$NEW_USER
# -G wheel: add the user to sudoers
# -s: set the default shell
useradd -m -G wheel -s /bin/bash $NEW_USER

# Takes the password as an input.
echo "Setting Password for $NEW_USER.."
passwd $NEW_USER

# Duplicated the ssh key from root
SSH_FOLDER=/home/$NEW_USER/.ssh
mkdir -p $SSH_FOLDER
cp /root/.ssh/* $SSH_FOLDER
# Change the owner of .ssh and subfolders to user
chown -R "$NEW_USER:$NEW_USER" $SSH_FOLDER
# Change access of .ssh folder to only user can access
chmod 700 $SSH_FOLDER
# Change access of ssh keys to only user can read and write
chmod 600 $SSH_FOLDER/*

WORKSPACE=/home/$NEW_USER/workspace
mkdir -p $WORKSPACE
mv /root/arch-linux $WORKSPACE

su $NEW_USER -c "cd $WORKSPACE/arch-linux && bash"

