#!/bin/bash
# Noctis Caeruleae - Build Script
# Installs all packages for the system image (no user configs)

set -eoux pipefail

echo "═══════════════════════════════════════════════════"
echo "  Noctis Caeruleae - Build Starting"
echo "═══════════════════════════════════════════════════"

# Create build log
mkdir -p /var/log
BUILDLOG="/var/log/noctis-caeruleae-build.log"
echo "Build started at $(date)" | tee -a $BUILDLOG

# ============================================
# PHASE 1: Compositor & Shell
# ============================================
echo ""
echo "📦 Installing niri compositor + noctalia-shell..."

rpm-ostree install \
    niri \
    noctalia-shell \
    brightnessctl \
    ImageMagick \
    python3 \
    git \
    cliphist \
    cava \
    wlsunset

# Remove unwanted packages pulled as dependencies
echo "Removing alacritty (replaced by ghostty)..."
rpm-ostree override remove alacritty || echo "⚠️  alacritty not found"
echo "Removing fuzzel (noctalia has its own launcher)..."
rpm-ostree override remove fuzzel || echo "⚠️  fuzzel not found"

# ============================================
# PHASE 2: Display Manager
# ============================================
echo ""
echo "🖥️  Installing greetd + tuigreet (NotAShelf fork)..."

rpm-ostree install greetd

# Download tuigreet from NotAShelf fork (has TOML config + bug fixes)
TUIGREET_VERSION="0.9.3"
curl -fsSL "https://github.com/NotAShelf/tuigreet/releases/download/${TUIGREET_VERSION}/tuigreet-${TUIGREET_VERSION}-x86_64" -o /usr/bin/tuigreet
chmod +x /usr/bin/tuigreet
echo "✓ tuigreet ${TUIGREET_VERSION} (NotAShelf fork) installed" | tee -a $BUILDLOG

# Create greeter user and group via sysusers.d (processed on first boot)
mkdir -p /usr/lib/sysusers.d
cat > /usr/lib/sysusers.d/greetd.conf <<'EOF'
g greeter -
u greeter - "Greeter user" /var/cache/tuigreet /usr/sbin/nologin
EOF

# Create cache directory for tuigreet --remember
mkdir -p /usr/lib/tmpfiles.d
cat > /usr/lib/tmpfiles.d/tuigreet.conf <<'EOF'
d /var/cache/tuigreet 0755 greeter greeter -
EOF

# Configure greetd to launch tuigreet
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet"
user = "greeter"
EOF

# Configure tuigreet via TOML (NotAShelf fork feature)
mkdir -p /etc/tuigreet
cat > /etc/tuigreet/config.toml <<'EOF'
# Tuigreet configuration (NotAShelf fork)
command = "niri-session"
sessions = "/usr/share/wayland-sessions"
time = true
remember = true
remember_user_session = true
asterisks = true
EOF

# Enable greetd service by default
mkdir -p /usr/lib/systemd/system-preset
echo "enable greetd.service" >> /usr/lib/systemd/system-preset/50-noctis-caeruleae.preset

echo "greetd + greeter user configured" | tee -a $BUILDLOG

# Configure console font for Unicode support (tuigreet borders)
cat > /etc/vconsole.conf <<'EOF'
KEYMAP="us"
FONT="Lat2-Terminus16"
EOF

echo "Console font configured for Unicode support" | tee -a $BUILDLOG

# ============================================
# PHASE 3: Terminal & Editor
# ============================================
echo ""
echo "💻 Installing terminal and editor..."

rpm-ostree install \
    ghostty \
    code

# ============================================
# PHASE 4: GNOME Apps (standalone, no gnome-shell)
# ============================================
echo ""
echo "📁 Installing GNOME apps..."

rpm-ostree install \
    nautilus \
    file-roller \
    gnome-disk-utility

# ============================================
# PHASE 5: Gaming
# ============================================
echo ""
echo "🎮 Installing gaming packages..."

rpm-ostree install \
    steam \
    gamemode

# ============================================
# PHASE 6: Dev Tools & Build Essentials
# ============================================
echo ""
echo "🛠️  Installing development tools..."

rpm-ostree install \
    git \
    gcc \
    gcc-c++ \
    make \
    cmake \
    pkg-config \
    nodejs \
    npm \
    python3 \
    python3-pip \
    rust \
    cargo \
    golang \
    zig \
    podman \
    podman-compose \
    unzip

# ============================================
# PHASE 7: Shell & CLI Tools
# ============================================
echo ""
echo "🐚 Installing shell and CLI tools..."

rpm-ostree install \
    fish \
    starship \
    eza \
    bat \
    yt-dlp \
    chezmoi \
    gh \
    input-remapper \
    keyd

# Configure keyd for Super tap = overview
# Create wrapper script (keyd runs as root, needs to access user's niri socket)
mkdir -p /usr/libexec/noctis
cat > /usr/libexec/noctis/keyd-mod <<'EOF'
#!/bin/bash
SOCKET=$(ls /run/user/1000/niri.*.sock 2>/dev/null | head -1)
runuser -u jvzr -- env NIRI_SOCKET="$SOCKET" niri msg action toggle-overview
EOF
chmod +x /usr/libexec/noctis/keyd-mod

mkdir -p /etc/keyd
cat > /etc/keyd/default.conf <<'EOF'
[ids]
*

[main]
# Super tap triggers overview via wrapper script
leftmeta = overload(meta, command(/usr/libexec/noctis/keyd-mod))
EOF

# Enable input-remapper and keyd services by default
mkdir -p /usr/lib/systemd/system-preset
echo "enable input-remapper.service" >> /usr/lib/systemd/system-preset/50-noctis-caeruleae.preset
echo "enable keyd.service" >> /usr/lib/systemd/system-preset/50-noctis-caeruleae.preset

# ============================================
# PHASE 8: Network Services
# ============================================
echo ""
echo "🌐 Installing network services..."

rpm-ostree install \
    tailscale

# ============================================
# PHASE 9: Custom Keyboard Layout
# ============================================
echo ""
echo "⌨️  Installing custom keyboard layout..."

# Extract the custom layout file from RPM (avoid file conflicts with xkeyboard-config)
cd /tmp/build_files
rpm2cpio xkb-qwerty-fr-0.7.3-2.noarch.rpm | cpio -idmv
cp -v usr/share/X11/xkb/symbols/us_qwerty-fr /usr/share/X11/xkb/symbols/
echo "✓ Custom QWERTY-FR layout installed" | tee -a $BUILDLOG

# ============================================
# PHASE 10: nirius (niri utilities)
# ============================================
echo ""
echo "📦 Installing nirius..."

export CARGO_HOME=/tmp/cargo
export RUSTUP_HOME=/tmp/rustup
cargo install nirius --root /usr
rm -rf /tmp/cargo /tmp/rustup

if [ -f /usr/bin/nirius ]; then
    echo "✓ nirius installed" | tee -a $BUILDLOG
else
    echo "⚠️  nirius installation failed" | tee -a $BUILDLOG
fi

# ============================================
# PHASE 11: Bun (via direct binary download)
# ============================================
echo ""
echo "📦 Installing bun..."

# Download and install bun binary directly to /usr/bin (ostree-compatible)
curl -fsSL https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip -o /tmp/bun.zip
unzip -q /tmp/bun.zip -d /tmp/
mv /tmp/bun-linux-x64/bun /usr/bin/
chmod +x /usr/bin/bun
rm -rf /tmp/bun.zip /tmp/bun-linux-x64

if [ -f /usr/bin/bun ]; then
    BUN_VERSION=$(bun --version)
    echo "✓ Bun $BUN_VERSION installed" | tee -a $BUILDLOG
else
    echo "⚠️  Bun installation failed" | tee -a $BUILDLOG
fi

# ============================================
# PHASE 11: Deno (via direct binary download)
# ============================================
echo ""
echo "📦 Installing deno..."

# Download and install deno binary directly to /usr/bin (ostree-compatible)
curl -fsSL https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -o /tmp/deno.zip
unzip -q /tmp/deno.zip -d /tmp/
mv /tmp/deno /usr/bin/
chmod +x /usr/bin/deno
rm -f /tmp/deno.zip

if [ -f /usr/bin/deno ]; then
    DENO_VERSION=$(deno --version | head -1)
    echo "✓ Deno $DENO_VERSION installed" | tee -a $BUILDLOG
else
    echo "⚠️  Deno installation failed" | tee -a $BUILDLOG
fi

# ============================================
# PHASE 12: Go tools (slit, doggo)
# ============================================
echo ""
echo "📦 Installing Go tools (slit, doggo)..."

export GOPATH=/tmp/go
export GOCACHE=/tmp/go-cache
export GOBIN=/usr/bin
go install github.com/tigrawap/slit/cmd/slit@latest
go install github.com/mr-karan/doggo/cmd/doggo@latest
rm -rf /tmp/go /tmp/go-cache

if [ -f /usr/bin/slit ]; then
    echo "✓ Slit installed" | tee -a $BUILDLOG
else
    echo "⚠️  Slit installation failed" | tee -a $BUILDLOG
fi

if [ -f /usr/bin/doggo ]; then
    DOGGO_VERSION=$(doggo --version 2>/dev/null | head -1 || echo "unknown")
    echo "✓ Doggo $DOGGO_VERSION installed" | tee -a $BUILDLOG
else
    echo "⚠️  Doggo installation failed" | tee -a $BUILDLOG
fi

# ============================================
# PHASE 13: Cleanup
# ============================================
echo ""
echo "🧹 Cleaning up..."

# Build files will be cleaned by Containerfile

echo ""
echo "Build completed at $(date)" | tee -a $BUILDLOG
echo "═══════════════════════════════════════════════════"
echo "  ✅ Noctis Caeruleae - Build Complete"
echo "═══════════════════════════════════════════════════"
echo ""
echo "📊 Build Summary:"
cat $BUILDLOG
