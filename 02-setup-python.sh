#!/bin/bash

# 1. Install System Python, Pip, and uv using yay
echo "--- Installing Python Ecosystem via yay ---"
yay -S --noconfirm python python-pip uv

# 2. Create the automation directory
# We only create the folder, no files inside yet!
mkdir -p automation

# 3. Initialize the Virtual Environment inside the folder
# This keeps your SRE libraries separate from the OS
echo "--- Initializing .venv in automation/ ---"
uv venv automation/.venv

# 4. Add a helper alias to your .zshrc if it doesn't exist
# This lets you jump into your 'automation' mode instantly
grep -q "alias activate-auto" ~/.zshrc || echo "alias activate-auto='source $(pwd)/automation/.venv/bin/activate'" >> ~/.zshrc

echo "--- Infrastructure Ready ---"
echo "Folder created: ./automation"
echo "Environment created: ./automation/.venv"
echo "Run 'source automation/.venv/bin/activate' to start working."
