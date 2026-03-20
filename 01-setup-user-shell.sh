#!/bin/bash

# 1. Install official Repo packages first
echo "--- Installing Zsh and Completions ---"
sudo pacman -Sy --noconfirm zsh zsh-completions zsh-autosuggestions

# 2. Use YAY for the Nerd Font (AUR)
echo "--- Installing Nerd Font from AUR ---"
yay -S --noconfirm fontconfig
yay -S --noconfirm ttf-meslo-nerd-font-powerlevel10k

# Verify Zsh was actually installed
if [ ! -f /bin/zsh ]; then
    echo "ERROR: Zsh failed to install. Check your network/pacman."
    exit 1
fi

# 2. Install Oh My Zsh (Unattended)
# We check if the folder exists first to make the script "Update-friendly"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "--- Installing Oh My Zsh ---"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed."
fi

# 3. Configure P10k Theme
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "--- Cloning Powerlevel10k ---"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 4. Final Config: Check if .zshrc exists before using 'sed'
if [ -f "$HOME/.zshrc" ]; then
    echo "--- Updating .zshrc theme ---"
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
else
    echo "ERROR: .zshrc not found. Creating a default one..."
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
fi

# Added to avoid typing the ssh key passphrase all the time
sed -i 's/plugins=(git)/plugins=(git ssh-agent)/' ~/.zshrc
grep -q "identities id_rsa" ~/.zshrc || echo 'zstyle :omz:plugins:ssh-agent identities id_ed25519' >> ~/.zshrc

# 2. Add the lifetime (4 hours)
grep -q "ssh-agent lifetime" ~/.zshrc || echo 'zstyle :omz:plugins:ssh-agent lifetime 4h' >> ~/.zshrc

# 5. Switch Shell
sudo chsh -s /bin/zsh "$USER"
echo "--- Shell setup complete. Please log out and back in! ---"
