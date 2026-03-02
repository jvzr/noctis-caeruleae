# Noctis Caeruleae

> *"De la nuit bleue"* - A clean Universal Blue image with niri + noctalia-shell

A minimal, elegant Fedora Silverblue-based immutable desktop featuring the niri scrollable-tiling Wayland compositor and noctalia-shell. **This image provides only the system layer** - user configuration is managed separately with [chezmoi](https://chezmoi.io/).

## Philosophy

**Separation of concerns:**
- **System** (this image): Immutable, packages only, versionned via ostree
- **User configs**: Mutable, managed with chezmoi in `$HOME`, persists across rebases

This approach keeps the system image clean and non-intrusive, while giving you full control over your personal configuration.

## Features

### Core Stack
- **Compositor**: [niri](https://github.com/YaLTeR/niri) - Scrollable-tiling Wayland compositor
- **Shell**: [noctalia-shell](https://noctalia.dev) - Sleek, minimal shell for Wayland
- **Base**: [Universal Blue](https://universal-blue.org/) base:stable (Fedora 43)
- **Display Manager**: greetd + tuigreet
- **Terminal**: Ghostty
- **Editor**: VSCode
- **Shell**: Fish + Starship
- **Dotfiles**: chezmoi (for user configuration management)

### Integrated Packages

#### Development Tools
- **Languages**: Rust, Go, Zig, Python, Node.js
- **Runtimes**: npm, bun, deno
- **Tools**: git, gcc, make, cmake, podman
- **CLI**: fish, starship, eza, bat, yt-dlp, chezmoi

#### Desktop Applications
- **File Manager**: Nautilus (GNOME Files)
- **Archive Manager**: File Roller
- **Disk Manager**: GNOME Disk Utility

#### Custom Components
- **Keyboard Layout**: xkb-qwerty-fr (French QWERTY custom layout)

### Flatpak Applications (Optional)

A helper script is provided to install 16 essential Flatpaks:

**Browsers** (3): Zen Browser, Ungoogled Chromium, Vivaldi
**System Tools** (5): Flatseal, Warehouse, Extension Manager, Dconf Editor, Mission Center
**Gaming** (5): Steam, Protontricks, ProtonPlus, Bottles, WineZGUI
**Productivity** (2): SyncThingy, SaveDesktop

### Security & Trust

- 🔒 **Cryptographically signed** - Every image is signed with cosign (Sigstore)
- ✅ **Signature verification** - Automatic verification on rebase
- 🔐 **Supply chain security** - GitHub OIDC keyless signing
- 🛡️ **Transparency** - All builds public and auditable

See [docs/SIGNING_AND_ISO.md](docs/SIGNING_AND_ISO.md) for details.

## Installation

Two installation methods are available:

### Option A: Rebase from existing system (Recommended)

**Prerequisites:**
- Existing Fedora Silverblue, Kinoite, or any Universal Blue image
- Internet connection

**With signature verification** (recommended):
```bash
# Rebase with automatic signature verification
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jvzr/noctis-caeruleae:latest

# Reboot
sudo systemctl reboot
```

**Without signature verification** (not recommended):
```bash
# Rebase without verification (use only if signature verification fails)
sudo rpm-ostree rebase ostree-unverified-registry:docker://ghcr.io/jvzr/noctis-caeruleae:latest

# Reboot
sudo systemctl reboot
```

### Option B: Fresh install from ISO

**For new installations or bare metal:**

1. Download the ISO from [GitHub Releases](https://github.com/jvzr/noctis-caeruleae/releases)
2. Verify the checksum:
   ```bash
   sha256sum -c noctis-caeruleae-*.iso.sha256sum
   ```
3. Create a bootable USB:
   ```bash
   # Linux
   sudo dd if=noctis-caeruleae-*.iso of=/dev/sdX bs=4M status=progress && sync

   # Or use Fedora Media Writer (GUI)
   ```
4. Boot from USB and follow the installation wizard
5. After reboot, Noctis Caeruleae is ready!

**Note:** ISOs are generated on-demand via GitHub Actions. See [docs/SIGNING_AND_ISO.md](docs/SIGNING_AND_ISO.md) for building your own ISO.

### Post-Installation

#### 1. Install Flatpaks (optional)
```bash
bash /usr/share/noctis-caeruleae/flatpak-install.sh
```

Or install manually:
```bash
flatpak install -y flathub app.zen_browser.zen com.vivaldi.Vivaldi ...
```

#### 2. Setup your dotfiles with chezmoi

**Option A: Use the example dotfiles**

```bash
# Initialize with the example dotfiles repo
chezmoi init --apply https://github.com/jvzr/noctis-caeruleae-dotfiles.git
```

This includes pre-configured:
- Fish shell (with eza, bat, starship integration)
- Ghostty terminal
- Niri compositor (optimized for noctalia-shell)

See [noctis-caeruleae-dotfiles](https://github.com/jvzr/noctis-caeruleae-dotfiles) for details.

**Option B: Use your own dotfiles**

If you already have a dotfiles repo:

```bash
chezmoi init https://github.com/jvzr/your-dotfiles.git
chezmoi diff  # Review changes
chezmoi apply
```

**Option C: Start fresh**

```bash
# Add your current configs to chezmoi
chezmoi add ~/.config/fish/config.fish
chezmoi add ~/.config/ghostty/config
chezmoi add ~/.config/niri/config.kdl

# Initialize git repo
cd ~/.local/share/chezmoi
git init
git add .
git commit -m "Initial dotfiles"
git remote add origin https://github.com/jvzr/dotfiles.git
git push -u origin main
```

#### 3. Daily chezmoi usage

```bash
# Update dotfiles from git
chezmoi update

# Edit a config
chezmoi edit ~/.config/fish/config.fish
chezmoi apply

# Add new configs
chezmoi add ~/.config/new-app/config.toml
```

See [chezmoi quick start](https://www.chezmoi.io/quick-start/) for more.

## Configuration

### Niri

Default config location: `~/.config/niri/config.kdl`

Key bindings (with example config):
- `Mod+Return` - Open terminal (Ghostty)
- `Mod+S` - Screenshot (interactive)
- `Ctrl+Print` - Screenshot full screen
- `Alt+Print` - Screenshot window
- `Mod+Shift+Q` - Close window
- `Mod+H/J/K/L` - Navigate windows (vim-style)
- `Mod+U/I` - Scroll workspaces (niri's unique feature!)

### Noctalia Shell

Config location: `~/.config/quickshell/noctalia-shell/`

See [noctalia documentation](https://docs.noctalia.dev/) for customization.

### Fish Shell

Config location: `~/.config/fish/`

The example dotfiles include:
- Starship prompt
- eza aliases (modern ls)
- bat aliases (modern cat)
- Custom functions

## Updates

### Update the System
```bash
# Update to latest image
rpm-ostree upgrade

# Reboot to apply
sudo systemctl reboot
```

### Update your dotfiles
```bash
# Pull and apply latest configs
chezmoi update
```

### Rollback
If something breaks, rollback to previous deployment:
```bash
rpm-ostree rollback
sudo systemctl reboot
```

## Troubleshooting

### Niri won't start
1. Check greetd logs: `journalctl -u greetd`
2. Try starting niri manually: `niri-session`
3. Rollback to previous deployment if needed

### Noctalia-shell not appearing
1. Check if quickshell is running: `ps aux | grep quickshell`
2. Manually start: `qs -c noctalia-shell`
3. Check niri config has `spawn-at-startup "qs" "-c" "noctalia-shell"`

### Network not working
NetworkManager is included in Universal Blue base. If issues:
```bash
systemctl status NetworkManager
nmcli device wifi list
```

### Audio not working
PipeWire is included in base. Check status:
```bash
systemctl --user status pipewire
```

### Dotfiles not applying
```bash
# See what chezmoi would do
chezmoi apply --dry-run --verbose

# Force apply (overwrites local changes)
chezmoi apply --force
```

## Development

### Build Locally
```bash
# Clone the repository
git clone https://github.com/jvzr/noctis-caeruleae.git
cd noctis-caeruleae

# Build with podman
podman build -t noctis-caeruleae:local -f Containerfile .
```

### Modify and Rebuild
1. Edit files in `build_files/` or `repos/`
2. Commit and push to GitHub
3. GitHub Actions will automatically rebuild
4. Rebase to the new build

### Project Structure
```
noctis-caeruleae/              # System image (this repo)
├── Containerfile              # Image definition
├── build_files/
│   ├── build.sh               # Main build script (includes chezmoi)
│   ├── niri-config.kdl        # Minimal default niri config
│   └── xkb-qwerty-fr-*.rpm    # Custom keyboard layout
├── config/
│   └── flatpak-install.sh     # Flatpak install helper
├── repos/                     # YUM repo definitions
│   ├── vscode.repo
│   ├── niri.repo
│   ├── noctalia.repo
│   └── ghostty.repo
└── .github/workflows/
    └── build.yml              # CI/CD

noctis-caeruleae-dotfiles/     # User configs (separate repo)
├── .chezmoi.toml.tmpl         # chezmoi configuration
├── dot_config/
│   ├── fish/                  # Fish shell configs
│   ├── ghostty/               # Ghostty config
│   └── niri/                  # Niri config
└── README.md
```

## Why chezmoi?

**Advantages over embedding configs in the image:**
- ✅ **Clean separation** - System image stays minimal and non-intrusive
- ✅ **User control** - You own your configs, not the image maintainer
- ✅ **Portability** - Same dotfiles work on multiple machines/distros
- ✅ **Versioning** - Full git history of your config changes
- ✅ **Templating** - Different configs per machine (laptop vs desktop)
- ✅ **Secrets** - Proper secret management (1Password, pass, etc.)
- ✅ **Updates** - `chezmoi update` pulls latest configs independently of system updates

**Alternative approaches:**
- Use your own dotfiles manager (stow, yadm, git, etc.)
- Manual config management
- Home Manager (Nix) - if you prefer declarative config

The image includes chezmoi as a convenience, but you're free to manage configs however you prefer!

## Installed Versions

Bun and Deno are installed via curl (no RPM packages available). Versions installed during the last build:
- Check build logs in GitHub Actions for exact versions

## Known Issues

- **Bun/Deno**: Installed via curl, versions not pinned (always latest)
- **Ghostty**: From COPR, evolves quickly, potential breaking changes
- **niri-git**: Git version, may have unstable features

## Credits

- **niri**: [@YaLTeR](https://github.com/YaLTeR/niri)
- **noctalia-shell**: [noctalia.dev](https://noctalia.dev)
- **Universal Blue**: [universal-blue.org](https://universal-blue.org/)
- **Ghostty**: [ghostty.org](https://ghostty.org/)
- **chezmoi**: [chezmoi.io](https://chezmoi.io/)
- **Inspiration**: [hyprblue](https://github.com/ashebanow/hyprblue), [slimblue](https://github.com/mrgrizzl/slimblue)

## License

This project follows the licensing of its components. See individual components for their respective licenses.

## Contributing

Contributions welcome! Please open an issue or PR.

## Support

For issues specific to this image:
- Open an issue on GitHub

For issues with components:
- niri: https://github.com/YaLTeR/niri/issues
- noctalia: https://github.com/noctalia-dev/noctalia-shell/issues
- Universal Blue: https://github.com/ublue-os/main/issues
- chezmoi: https://github.com/twpayne/chezmoi/issues
