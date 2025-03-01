# dotfiles

This is a dotfiles setup for MacOS.

## Installation

***These steps assume a fresh install of MacOS.***

### Prerequisites

- [Setup a SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [link it in Github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- [Homebrew](https://brew.sh/)
- [Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases)

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

### Setup Kanata
Unfortunately, MacOS makes it a little complicated to setup Kanata.
First, you should have [Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases) installed and activated.
After installing the driver, you can activate it with:

```sh
sudo /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
```

Then you should navigate to ` > System Settings > Privacy & Security > Input Monitoring`, and click the `+` icon to try to add Kanata to the list.
This part is a bit tricky because the file picker doesn't make it easy to find homebrew's bin directory.
The easiest way I have found is to navigate via terminal and open finder from there.
While, leaving the picker to add a new program where it is, open a terminal window and run the following:

```sh
open /opt/homebrew/bin/ 
```

In the resulting finder window, locate Kanata and drag it over to the 'Add Program' picker from before.
This should add Kanata to the list, and make sure it is toggled on.
Restart the service (or just restart your computer) and Kanata should be good to go.
If the `D` and `K` keys aren't working as `Shift` keys, then something is wrong.
You can check the error logs for Kanata and debug from there with this command:

```sh
sudo tail -f /Library/Logs/Kanata/kanata.err.log
```

### Make this repo your own (Optional)
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
- Remember to update the `setupEnv.zsh` to create a symbolic link to any new config directory
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


