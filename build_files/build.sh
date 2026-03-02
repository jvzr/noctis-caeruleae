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

# ============================================
# PHASE 2: Display Manager
# ============================================
echo ""
echo "🖥️  Installing greetd + tuigreet..."

rpm-ostree install \
    greetd \
    tuigreet

# Configure greetd
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd niri-session"
user = "greeter"
EOF

echo "greetd configured" | tee -a $BUILDLOG

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
# PHASE 5: Dev Tools & Build Essentials
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
    podman-compose

# ============================================
# PHASE 6: Shell & CLI Tools
# ============================================
echo ""
echo "🐚 Installing shell and CLI tools..."

rpm-ostree install \
    fish \
    starship \
    eza \
    bat \
    yt-dlp \
    chezmoi

# ============================================
# PHASE 7: Custom Keyboard Layout
# ============================================
echo ""
echo "⌨️  Installing custom keyboard layout..."

# Extract the custom layout file from RPM (avoid file conflicts with xkeyboard-config)
cd /tmp/build_files
rpm2cpio xkb-qwerty-fr-0.7.3-2.noarch.rpm | cpio -idmv
cp -v usr/share/X11/xkb/symbols/us_qwerty-fr /usr/share/X11/xkb/symbols/
echo "✓ Custom QWERTY-FR layout installed" | tee -a $BUILDLOG

# ============================================
# PHASE 8: Bun (via curl - no RPM available)
# ============================================
echo ""
echo "📦 Installing bun..."

export BUN_INSTALL=/usr/local
curl -fsSL https://bun.sh/install | bash
if [ -f /usr/local/bin/bun ]; then
    BUN_VERSION=$(/usr/local/bin/bun --version)
    echo "✓ Bun $BUN_VERSION installed" | tee -a $BUILDLOG
else
    echo "⚠️  Bun installation failed" | tee -a $BUILDLOG
fi

# ============================================
# PHASE 9: Deno (via curl - no RPM available)
# ============================================
echo ""
echo "📦 Installing deno..."

export DENO_INSTALL=/usr/local
curl -fsSL https://deno.land/install.sh | sh
if [ -f /usr/local/bin/deno ]; then
    DENO_VERSION=$(/usr/local/bin/deno --version | head -1)
    echo "✓ Deno $DENO_VERSION installed" | tee -a $BUILDLOG
else
    echo "⚠️  Deno installation failed" | tee -a $BUILDLOG
fi

# ============================================
# PHASE 10: Cleanup
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
