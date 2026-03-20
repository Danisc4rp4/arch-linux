#!/bin/bash

# 1. Install Python and uv using yay
echo "--- Installing Python and uv via yay ---"
yay -S --noconfirm python uv

# 2. Create the automation folder
mkdir -p automation

# 3. Initialize the Python environment inside the folder
echo "--- Initializing isolated Python environment ---"
uv venv automation/.venv

# 4. Create a starter SRE script
cat <<'EOF' > automation/check_infra.py
import os
import sys

def main():
    print("--- SRE Automation Tool ---")
    venv = os.getenv('VIRTUAL_ENV')
    if venv:
        print(f"Status: Running in isolated environment: {venv}")
    else:
        print("Warning: Not running in a virtual environment!")
    
    print(f"Python interpreter: {sys.executable}")

if __name__ == "__main__":
    main()
EOF

# 5. Make the script executable
chmod +x automation/check_infra.py

echo "--- Setup Complete ---"
echo "To activate your environment: source automation/.venv/bin/activate"
