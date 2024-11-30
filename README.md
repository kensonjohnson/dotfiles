# dotfiles

This is a dotfiles setup for MacOS.

## Installation

***These steps assume a fresh install of MacOS.***

### Prerequisites

- [Setup a SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [link it in Github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- [Homebrew](https://brew.sh/)

### Steps

1. Clone this repo, if not already done. 
The repo must be cloned into the root:

```sh
git clone git@github.com:kensonjohnson/dotfiles.git ~/.dotfiles
cd ~/.dotfiles/
```

2. Install programs via `brew bundle`:
```sh
brew bundle install --file=~/.dotfiles/Brewfile
```

3. Create symlinks to config files:
```sh
zsh ~/.dotfiles/setupEnv.zsh
```

4. (Optional) Make this repo your own:
```sh
# Change into the project directory
cd ~/.dotfiles/

# Nuke the .git directory
rm .git

# Create a new git repo and commit everything
git init
git add .
git commit -m "initial commit"

# Push the files up to your Github repo
# Just plug in your username and repo name below
# NOTE: This assumes that you initialized an empty repo on Github
git branch -M main
git remote add origin git@github.com:<your-username>/<your-repo-name>.git
git push -u origin main
```

## Usage

### Updating the Repo

Tips for updating your config:

- Make a feature branch, do your work, and merge it back into `main` when you're done
- Try to keep concepts in their own directories, e.g. `nvim` for Neovim's config
- Remember to update the `setupEnv.zsh` as if you had to link a new config file
- Remember to update your `brewfile` if you add any new programs

### Updating the Brewfile

Homebrew Bundle comes installed automatically when you install Homebrew.
In the `zshrc` file, we instruct `brew bundle` to use the `Brewfile` located in this project.
So, to update the `Brewfile`, you can simply call:

```sh
brew bundle dump --force
```

If you are using VS Code and would like your extensions to be included in the `Brewfile` dump, you will need to remove `HOMEBREW_BUNDLE_DUMP_NO_VSCODE=true` from the top of the `zshenv` file.
After removing that line, run the dump again and all of your extensions should be recorded.


