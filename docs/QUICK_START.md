# Quick Start - Noctis Caeruleae

Guide rapide pour démarrer avec Noctis Caeruleae.

---

## 🚀 Pour l'utilisateur final

### Installation rapide (rebase)

```bash
# Avec signature vérifiée (recommandé)
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jvzr/noctis-caeruleae:latest
sudo systemctl reboot

# Après le reboot:
# 1. Installer les Flatpaks
bash /usr/share/noctis-caeruleae/flatpak-install.sh

# 2. Appliquer vos dotfiles
chezmoi init --apply https://github.com/jvzr/noctis-caeruleae-dotfiles.git
```

### Installation ISO

1. Télécharger ISO depuis GitHub Releases
2. Créer USB bootable: `sudo dd if=noctis-*.iso of=/dev/sdX bs=4M && sync`
3. Booter et installer
4. Après install: appliquer dotfiles avec chezmoi

---

## 🛠️ Pour le mainteneur (vous)

### Setup initial

```bash
# 1. Créer les repos GitHub
# - noctis-caeruleae (image système)
# - noctis-caeruleae-dotfiles (configs user)

# 2. Push l'image système
cd dev/noctis-caeruleae
git init
git add .
git commit -m "Initial commit: Noctis Caeruleae with signing and ISO support"
git remote add origin https://github.com/jvzr/noctis-caeruleae.git
git push -u origin main

# 3. Push les dotfiles
cd ../noctis-caeruleae-dotfiles
git init
git add .
git commit -m "Initial dotfiles with chezmoi"
git remote add origin https://github.com/jvzr/noctis-caeruleae-dotfiles.git
git push -u origin main
```

### Build automatique

**À chaque push sur `main`:**
- ✅ Image buildée automatiquement
- ✅ Signée avec cosign (keyless via GitHub OIDC)
- ✅ Publiée sur ghcr.io
- ✅ Rebuild hebdomadaire (dimanche 00:00)

### Générer un ISO

```bash
# Via GitHub Actions UI
1. Aller sur Actions > Build ISO > Run workflow
2. Télécharger l'ISO depuis Artifacts

# Ou via release:
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 --title "Noctis Caeruleae v1.0.0"
# GitHub Actions attachera automatiquement l'ISO à la release
```

### Vérifier la signature localement

```bash
# Installer cosign
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Vérifier
cosign verify ghcr.io/jvzr/noctis-caeruleae:latest \
  --certificate-identity-regexp=https://github.com/jvzr \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

---

## 📁 Structure du projet

```
noctis-caeruleae/               # Image système
├── .github/workflows/
│   ├── build.yml               # Build + Sign automatique
│   └── build-iso.yml           # Génération ISO
├── build_files/
│   ├── build.sh                # Script de build (inclut chezmoi)
│   ├── niri-config.kdl         # Config système minimale
│   └── xkb-qwerty-fr-*.rpm     # Layout clavier
├── config/
│   └── flatpak-install.sh      # Helper Flatpaks
├── docs/
│   ├── SIGNING_AND_ISO.md      # Guide complet signature + ISO
│   └── QUICK_START.md          # Ce fichier
├── repos/                      # 4 repos COPR/Microsoft
├── Containerfile               # Définition image
├── image.yml                   # Config BlueBuild ISO
└── README.md                   # Documentation principale

noctis-caeruleae-dotfiles/      # Configs user (repo séparé)
├── dot_config/
│   ├── fish/                   # Fish shell
│   ├── ghostty/                # Terminal
│   └── niri/                   # Compositor
├── .chezmoi.toml.tmpl          # Config chezmoi
└── README.md                   # Guide chezmoi
```

---

## 🔄 Workflow typique

### Modifier l'image système

```bash
cd noctis-caeruleae

# Modifier build.sh, Containerfile, repos/, etc.
vim build_files/build.sh

# Commit et push
git add .
git commit -m "Add new package XYZ"
git push

# GitHub Actions build automatiquement
# Après ~30min: nouvelle image disponible

# Les utilisateurs peuvent rebase:
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jvzr/noctis-caeruleae:latest
```

### Modifier les dotfiles

```bash
cd noctis-caeruleae-dotfiles

# Modifier configs
vim dot_config/fish/config.fish

# Commit et push
git add .
git commit -m "Update fish aliases"
git push

# Les utilisateurs peuvent update:
chezmoi update
```

---

## 🎯 Checklist avant release

- [ ] Build passe sur GitHub Actions
- [ ] Image signée (vérifier avec cosign)
- [ ] ISO généré et testé dans VM
- [ ] README à jour avec vos URLs
- [ ] Dotfiles repo pushé
- [ ] Tag créé: `git tag v1.0.0 && git push origin v1.0.0`
- [ ] Release GitHub avec ISO attaché

---

## 🐛 Troubleshooting

### Build échoue

- Vérifier logs GitHub Actions
- Tester build local: `podman build -t test -f Containerfile .`
- Vérifier COPR repos disponibles

### Signature échoue

- Vérifier permissions GitHub Actions (id-token: write)
- Vérifier cosign-installer version

### ISO ne boot pas

- Vérifier avec `file noctis-*.iso` (doit être "ISO 9660")
- Tester dans VM: `virt-install --cdrom noctis-*.iso ...`

### Rebase échoue avec signature

```bash
# Fallback sans signature temporairement:
sudo rpm-ostree rebase ostree-unverified-registry:docker://ghcr.io/jvzr/noctis-caeruleae:latest
```

---

## 📚 Ressources

- **Documentation complète**: [docs/SIGNING_AND_ISO.md](SIGNING_AND_ISO.md)
- **README principal**: [../README.md](../README.md)
- **Dotfiles README**: Voir repo noctis-caeruleae-dotfiles
- **Universal Blue**: https://universal-blue.org/
- **BlueBuild**: https://blue-build.org/
- **cosign**: https://docs.sigstore.dev/

---

## ❓ Questions fréquentes

### Pourquoi deux repos?

**Séparation système/user**:
- `noctis-caeruleae`: Image système immutable (ostree)
- `noctis-caeruleae-dotfiles`: Configs user mutables (git+chezmoi)

Le `/home` persiste entre rebases d'image.

### Puis-je modifier l'image sans rebuild?

Non, c'est une image immutable. Mais vous pouvez:
- Layer packages: `rpm-ostree install package`
- Modifier dotfiles: `chezmoi edit ...`
- Installer Flatpaks: `flatpak install ...`

Pour modifications permanentes: éditer Containerfile/build.sh et rebuild.

### Comment contribuer?

1. Fork les repos
2. Faire vos modifications
3. Tester localement
4. Ouvrir une PR

### L'image est trop grosse?

Retirer des packages de `build.sh`:
- Langages de dev pas utilisés (rust, go, zig)
- Outils CLI superflus
- Rebuild

---

Besoin d'aide? Ouvrir une issue sur GitHub! 🚀
