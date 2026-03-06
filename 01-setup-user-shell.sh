#!/bin/bash

sudo pacman -Sy --noconfirm zsh zsh-completions zsh-autosuggestions ttf-meslo-nerd-font-powerlevel10k

# --unattended: Don't ask questions
# --keep-zshrc: Don't overwrite any changes we already made
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

# Clone the P10k repo
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Change the theme line in .zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

