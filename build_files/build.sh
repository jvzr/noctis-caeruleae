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

# Remove alacritty (noctalia-shell dependency) - we use ghostty instead
echo "Removing alacritty (replaced by ghostty)..."
rpm-ostree override remove alacritty || echo "⚠️  alacritty not found (might not be a dependency)"

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
    podman-compose \
    unzip

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
# PHASE 7: Network Services
# ============================================
echo ""
echo "🌐 Installing network services..."

rpm-ostree install \
    tailscale

# ============================================
# PHASE 8: Custom Keyboard Layout
# ============================================
echo ""
echo "⌨️  Installing custom keyboard layout..."

# Extract the custom layout file from RPM (avoid file conflicts with xkeyboard-config)
cd /tmp/build_files
rpm2cpio xkb-qwerty-fr-0.7.3-2.noarch.rpm | cpio -idmv
cp -v usr/share/X11/xkb/symbols/us_qwerty-fr /usr/share/X11/xkb/symbols/
echo "✓ Custom QWERTY-FR layout installed" | tee -a $BUILDLOG

# ============================================
# PHASE 9: Bun (via direct binary download)
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
# PHASE 10: Deno (via direct binary download)
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
# PHASE 11: Cleanup
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
