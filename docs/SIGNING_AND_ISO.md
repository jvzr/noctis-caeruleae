# Signature d'image et génération d'ISO

Guide complet pour signer votre image Noctis Caeruleae et générer un ISO d'installation.

---

## 🔐 Partie 1: Signature d'image (cosign)

### Qu'est-ce que la signature d'image?

La signature cryptographique permet de:
- ✅ **Vérifier l'authenticité** - L'image vient bien de vous
- ✅ **Garantir l'intégrité** - L'image n'a pas été modifiée
- ✅ **Sécurité Supply Chain** - Protection contre les attaques MITM

Universal Blue utilise **cosign** (Sigstore) pour signer toutes les images.

### Configuration automatique

✅ **Déjà configuré!** Le workflow GitHub Actions inclut:
- Installation de cosign
- Signature automatique après chaque build
- Vérification de la signature
- Signature "keyless" via GitHub OIDC (pas de clés à gérer)

### Comment ça fonctionne

#### Lors du build (GitHub Actions)
```bash
# Après le build, GitHub Actions exécute:
cosign sign --yes ghcr.io/jvzr/noctis-caeruleae@sha256:abc123...

# Vérification automatique:
cosign verify ghcr.io/jvzr/noctis-caeruleae@sha256:abc123... \
  --certificate-identity-regexp=https://github.com/jvzr \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

La signature est stockée dans le registry avec l'image (transparence totale).

### Utilisation: Rebase avec vérification

**Avant (sans signature)**:
```bash
# ⚠️ Pas de vérification
sudo rpm-ostree rebase ostree-unverified-registry:docker://ghcr.io/jvzr/noctis-caeruleae:latest
```

**Après (avec signature)** ✅:
```bash
# ✅ Vérifie automatiquement la signature
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jvzr/noctis-caeruleae:latest
```

### Vérification manuelle de la signature

```bash
# Installer cosign localement
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Vérifier une image
cosign verify ghcr.io/jvzr/noctis-caeruleae:latest \
  --certificate-identity-regexp=https://github.com/jvzr \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**Sortie attendue**:
```
Verification for ghcr.io/jvzr/noctis-caeruleae:latest --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates

[
  {
    "critical": {
      "identity": {
        "docker-reference": "ghcr.io/jvzr/noctis-caeruleae"
      },
      "type": "cosign container image signature"
    }
  }
]
```

### Configuration de la politique de signature

Pour forcer la vérification des signatures sur votre machine:

```bash
# Créer un fichier de politique
sudo mkdir -p /etc/containers/registries.d

sudo tee /etc/containers/registries.d/ghcr.io-jvzr.yaml <<EOF
docker:
  ghcr.io/USER:
    use-sigstore-attachments: true
EOF

# Redémarrer
sudo systemctl reboot
```

Maintenant, toute image de `ghcr.io/jvzr/*` sera automatiquement vérifiée.

---

## 💿 Partie 2: Génération d'ISO

### Pourquoi un ISO?

Un ISO permet:
- ✅ **Installation fraîche** - Pas besoin d'une base Silverblue existante
- ✅ **USB bootable** - Installation physique sur n'importe quelle machine
- ✅ **Offline install** - Pas besoin d'internet pour l'installation initiale

### Option A: BlueBuild ISO (Recommandé) ⭐

**BlueBuild** est le système moderne recommandé par Universal Blue.

#### 1. Prérequis

```bash
# Sur Fedora/Universal Blue
sudo rpm-ostree install podman

# Ou utiliser GitHub Actions (recommandé)
```

#### 2. Créer le fichier de configuration

Créez `image.yml` à la racine du projet:

```yaml
# image.yml - BlueBuild ISO configuration
name: noctis-caeruleae
description: Noctis Caeruleae - A clean Universal Blue image with niri + noctalia-shell
base-image: ghcr.io/ublue-os/base
image-version: 43

installer:
  enabled: true
  type: anaconda
  # Optionnel: personnaliser l'installeur
  kickstart:
    locale: fr_FR.UTF-8
    keyboard: fr-qwerty-custom
    timezone: Europe/Paris
    network: --bootproto=dhcp
```

#### 3. Build l'ISO avec GitHub Actions

Créez `.github/workflows/build-iso.yml`:

```yaml
name: Build ISO

on:
  workflow_dispatch:
  release:
    types: [published]

jobs:
  build-iso:
    name: Build Installation ISO
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build ISO
        uses: blue-build/github-action@v1.6
        with:
          recipe: image.yml
          build_iso: true

      - name: Upload ISO
        uses: actions/upload-artifact@v4
        with:
          name: noctis-caeruleae-iso
          path: "*.iso"
          retention-days: 7

      - name: Upload ISO to Release
        if: github.event_name == 'release'
        uses: softprops/action-gh-release@v1
        with:
          files: "*.iso"
```

#### 4. Déclencher le build

```bash
# Via l'interface GitHub: Actions > Build ISO > Run workflow

# Ou créer un release:
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 --title "Noctis Caeruleae v1.0.0"
```

#### 5. Utiliser l'ISO

```bash
# Télécharger l'ISO depuis GitHub Releases ou Artifacts

# Créer une clé USB bootable (Linux)
sudo dd if=noctis-caeruleae-43-latest.iso of=/dev/sdX bs=4M status=progress && sync

# Ou avec Fedora Media Writer (GUI)
# Ou avec Ventoy (multi-boot)
```

### Option B: Universal Blue ISO (Méthode officielle)

Si vous voulez utiliser l'infrastructure officielle Universal Blue:

#### 1. Fork le repo ISO

```bash
git clone https://github.com/ublue-os/isogenerator.git
cd isogenerator
```

#### 2. Modifier `config.yml`

```yaml
image:
  name: noctis-caeruleae
  url: ghcr.io/jvzr/noctis-caeruleae
  tag: latest
  signed: true

iso:
  name: noctis-caeruleae-live
  release: "43"
  variant: Silverblue

branding:
  name: "Noctis Caeruleae"
  shortname: "noctis-caeruleae"
```

#### 3. Build localement

```bash
# Installer les dépendances
sudo dnf install lorax anaconda

# Build l'ISO
sudo ./build-iso.sh
```

#### 4. Ou via GitHub Actions

Push votre fork et le workflow générera l'ISO automatiquement.

### Option C: Build manuel (Avancé)

Pour un contrôle total:

#### 1. Préparer l'environnement

```bash
# Sur Fedora
sudo dnf install lorax anaconda pykickstart

# Créer un répertoire de travail
mkdir -p ~/iso-build && cd ~/iso-build
```

#### 2. Créer un kickstart

`noctis-caeruleae.ks`:
```kickstart
# Kickstart for Noctis Caeruleae
lang fr_FR.UTF-8
keyboard fr-qwerty-custom
timezone Europe/Paris

# Network
network --bootproto=dhcp --device=link --activate

# OSTree setup
ostreesetup --osname=fedora --remote=noctis-caeruleae \
  --url=https://ghcr.io/jvzr/noctis-caeruleae \
  --ref=ostree-image-signed:docker://ghcr.io/jvzr/noctis-caeruleae:latest

# Users
rootpw --lock
user --name=user --groups=wheel --plaintext --password=changeme

# Boot
bootloader --location=mbr --boot-drive=sda
```

#### 3. Build avec lorax

```bash
# Créer l'ISO
sudo lorax -p Noctis-Caeruleae -v 43 -r 43 \
  --repo=https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/ \
  --installpkgs=fedora-release \
  --add-template=/path/to/noctis-caeruleae.ks \
  --nomacboot \
  iso-output/
```

---

## 📊 Comparaison des méthodes

| Méthode | Difficulté | Contrôle | Recommandé pour |
|---------|-----------|----------|----------------|
| **BlueBuild ISO** | ⭐ Facile | Moyen | La plupart des cas |
| **UBlue ISO** | ⭐⭐ Moyen | Moyen | Intégration UBlue |
| **Manuel (lorax)** | ⭐⭐⭐ Difficile | Total | Besoins spécifiques |

---

## 🚀 Workflow recommandé

### Configuration finale pour production

1. **Signature automatique** ✅ (déjà configuré)
2. **Build ISO automatique** via BlueBuild
3. **Release GitHub** avec ISO attaché

### Fichiers à créer

```
noctis-caeruleae/
├── .github/
│   └── workflows/
│       ├── build.yml           # ✅ Déjà créé (avec signature)
│       └── build-iso.yml       # À créer
├── image.yml                   # Configuration BlueBuild
├── Containerfile
└── ...
```

---

## 🎯 Actions à faire

### 1. Activer la signature (Déjà fait ✅)

Le workflow est déjà configuré. Au prochain push sur `main`:
- L'image sera buildée
- Signée automatiquement avec cosign
- Publiée sur ghcr.io
- Vérifiable avec `ostree-image-signed:`

### 2. Générer un ISO

**Méthode rapide (BlueBuild)**:

```bash
# 1. Créer image.yml
cat > image.yml <<'EOF'
name: noctis-caeruleae
description: A clean Universal Blue image with niri + noctalia-shell
base-image: ghcr.io/ublue-os/base
image-version: 43
installer:
  enabled: true
EOF

# 2. Créer .github/workflows/build-iso.yml (voir contenu ci-dessus)

# 3. Commit et push
git add image.yml .github/workflows/build-iso.yml
git commit -m "Add ISO generation support"
git push

# 4. Déclencher le build via GitHub Actions UI
```

### 3. Tester l'ISO

```bash
# Télécharger depuis GitHub Actions Artifacts
# Tester dans une VM
virt-install --name noctis-test --memory 4096 --vcpus 2 \
  --disk size=40 --cdrom noctis-caeruleae-43-latest.iso \
  --graphics vnc,listen=0.0.0.0
```

---

## 📝 Utilisation finale

### Pour les utilisateurs existants (rebase)

```bash
# Avec signature vérifiée
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jvzr/noctis-caeruleae:latest
sudo systemctl reboot
```

### Pour les nouvelles installations (ISO)

1. Télécharger l'ISO depuis GitHub Releases
2. Créer une clé USB bootable
3. Booter et installer normalement
4. Au premier démarrage, l'image Noctis Caeruleae est déjà installée

---

## 🔒 Sécurité

### Bonnes pratiques

✅ **Toujours utiliser `ostree-image-signed:`** (pas `ostree-unverified-registry:`)
✅ **Pinner les versions** avec digest pour production
✅ **Vérifier les signatures** avant déploiement critique
✅ **Rebuild hebdomadaire** (déjà configuré via cron)

### Commande de rebase sécurisée pour production

```bash
# Avec digest spécifique (immutable)
sudo rpm-ostree rebase \
  ostree-image-signed:docker://ghcr.io/jvzr/noctis-caeruleae@sha256:abc123...
```

Le digest est affiché dans le GitHub Actions summary après chaque build.

---

## 📚 Ressources

- **Sigstore/cosign**: https://docs.sigstore.dev/
- **BlueBuild**: https://blue-build.org/
- **Universal Blue ISO**: https://github.com/ublue-os/isogenerator
- **rpm-ostree signing**: https://coreos.github.io/rpm-ostree/container/#signature-verification
- **Anaconda kickstart**: https://pykickstart.readthedocs.io/

---

## ❓ FAQ

### L'image est-elle signée maintenant?

Oui! Dès le prochain push sur `main`, l'image sera automatiquement signée.

### Puis-je utiliser mes propres clés?

Oui, mais la signature keyless (via GitHub OIDC) est recommandée. Pour utiliser vos clés:

```yaml
# Dans .github/workflows/build.yml
- name: Sign with custom key
  run: |
    cosign sign --key cosign.key \
      ${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}
```

Mais vous devrez gérer les clés (rotation, sécurité, distribution de la clé publique).

### L'ISO inclut-il les configs user?

Non, l'ISO installe juste l'image système. Les dotfiles doivent être appliqués après:

```bash
# Après installation depuis ISO
chezmoi init --apply https://github.com/jvzr/noctis-caeruleae-dotfiles.git
```

### Puis-je créer un ISO avec dotfiles pré-configurés?

Oui, via le kickstart. Ajoutez dans `%post`:

```kickstart
%post
# Install dotfiles automatically
sudo -u user chezmoi init --apply https://github.com/jvzr/noctis-caeruleae-dotfiles.git
%end
```

Mais ce n'est pas recommandé (viole la séparation système/user).
