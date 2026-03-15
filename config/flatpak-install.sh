#!/bin/bash
# Noctis Caeruleae - Flatpak installation script
# Install the 16 essential Flatpaks for this image

echo "═══════════════════════════════════════════════════"
echo "  Noctis Caeruleae - Installing Essential Flatpaks"
echo "═══════════════════════════════════════════════════"
echo ""

# Navigateurs (3)
echo "📦 Installing browsers..."
flatpak install -y flathub \
    app.zen_browser.zen \
    io.github.ungoogled_software.ungoogled_chromium \
    com.vivaldi.Vivaldi

echo ""
# Outils système (5)
echo "🔧 Installing system tools..."
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    io.github.flattool.Warehouse \
    io.github.kolunmi.Bazaar \
    com.mattjakeman.ExtensionManager \
    ca.desrt.dconf-editor \
    io.missioncenter.MissionCenter

echo ""
# Gaming (5)
echo "🎮 Installing gaming tools..."
flatpak install -y flathub \
    com.github.Matoking.protontricks \
    com.vysp3r.ProtonPlus \
    com.usebottles.bottles \
    io.github.fastrizwaan.WineZGUI \
    com.valvesoftware.Steam

echo ""
# Productivité (2)
echo "📝 Installing productivity apps..."
flatpak install -y flathub \
    com.github.zocker_160.SyncThingy \
    io.github.vikdevelop.SaveDesktop

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ Flatpak installation complete!"
echo "═══════════════════════════════════════════════════"
