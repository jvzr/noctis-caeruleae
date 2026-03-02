ARG IMAGE_NAME="${IMAGE_NAME:-base-main}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${IMAGE_NAME}"
ARG IMAGE_TAG="${IMAGE_TAG:-stable}"

FROM ${BASE_IMAGE}:${IMAGE_TAG} AS noctis-caeruleae

# ============================================
# Metadata
# ============================================
LABEL org.opencontainers.image.title="Noctis Caeruleae"
LABEL org.opencontainers.image.description="Universal Blue custom image with niri + noctalia-shell"
LABEL org.opencontainers.image.source="https://github.com/jvzr/noctis-caeruleae"
LABEL org.opencontainers.image.authors="jvzr"

# ============================================
# PHASE 1: Setup repositories
# ============================================
# Copy COPR and Microsoft repository files
COPY repos/*.repo /etc/yum.repos.d/

# Import GPG keys
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    rpm --import https://copr-be.cloud.fedoraproject.org/results/yalter/niri-git/pubkey.gpg && \
    rpm --import https://copr-be.cloud.fedoraproject.org/results/zhangyi6324/noctalia-shell/pubkey.gpg && \
    rpm --import https://copr-be.cloud.fedoraproject.org/results/pgdev/ghostty/pubkey.gpg

# ============================================
# PHASE 2: Run build script
# ============================================
# Copy build files
COPY build_files /tmp/build_files

# Make build script executable and run
RUN chmod +x /tmp/build_files/build.sh && \
    /tmp/build_files/build.sh && \
    ostree container commit

# ============================================
# PHASE 3: Install Flatpak helper script
# ============================================
# Copy flatpak install script to system location
COPY config/flatpak-install.sh /usr/share/noctis-caeruleae/flatpak-install.sh
RUN chmod +x /usr/share/noctis-caeruleae/flatpak-install.sh

# ============================================
# PHASE 4: Configure display manager
# ============================================
# Enable greetd, disable GDM
RUN systemctl disable gdm.service || true && \
    systemctl enable greetd.service

# ============================================
# PHASE 5: Cleanup
# ============================================
# Clean up build files
RUN rm -rf /tmp/build_files

# ============================================
# Final ostree commit
# ============================================
RUN ostree container commit
