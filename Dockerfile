# Container machine image for igara development.
# Used with `apple/container` (https://github.com/apple/container) via
# `container machine create` + VS Code Remote-SSH.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# System packages: sshd + systemd (required by container machine),
# plus dev toolchain (git, gh, build tools, curl, etc.).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg2 lsb-release \
      git sudo vim less \
      openssh-server systemd systemd-sysv \
      build-essential python3 pkg-config \
      tzdata locales \
 && locale-gen en_US.UTF-8 ja_JP.UTF-8 \
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.js 20 (matches package.json engines >=20.9.0) + corepack (pnpm 9.15.4)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && corepack enable \
 && corepack prepare pnpm@9.15.4 --activate \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Claude Code (container-local install; keeps ~/.claude isolated from macOS)
RUN npm install -g @anthropic-ai/claude-code

# Passwordless sudo for all users (container machine auto-creates the host user)
RUN echo 'ALL ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd \
 && chmod 0440 /etc/sudoers.d/nopasswd

# OpenSSH: password + pubkey auth, no root, fast handshake for loopback/local use
RUN mkdir -p /var/run/sshd \
 && ssh-keygen -A \
 && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'                    /etc/ssh/sshd_config \
 && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/'     /etc/ssh/sshd_config \
 && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/'         /etc/ssh/sshd_config \
 && echo 'UseDNS no'               >> /etc/ssh/sshd_config \
 && echo 'GSSAPIAuthentication no' >> /etc/ssh/sshd_config \
 && systemctl enable ssh

# Prevent noisy/blocking units in the VM
RUN systemctl mask getty@.service systemd-logind.service \
      apt-daily.timer apt-daily-upgrade.timer fstrim.timer || true

# SSH login helper. HOME stays as the Linux-native /home/$USER so that
# ~/.claude, ~/.local/bin, ~/.gitconfig etc. are container-isolated and
# do NOT pick up macOS host files (which would cause 'Exec format error'
# for host binaries, and leak container writes into the host home).
# The macOS repo mounted at /Users/$USER/github/igara is
# "expanded" into $HOME: each top-level entry of the repo is symlinked
# directly under ~ (e.g. ~/repos, ~/Dockerfile), so the repo contents
# live at /home/$USER/* instead of nested under ~/igara. Entries that
# would collide with a container-isolated home file (.claude, .gitconfig,
# .local, .ssh, .bashrc, .profile, ...) are skipped.
RUN cat > /etc/profile.d/00-igara-workspace.sh <<'EOF'
# shellcheck shell=sh
_igara_src="/Users/$USER/github/igara"
if [ -d "$_igara_src" ]; then
  for _entry in "$_igara_src"/* "$_igara_src"/.[!.]*; do
    [ -e "$_entry" ] || continue
    _name=$(basename "$_entry")
    _dest="$HOME/$_name"
    # Skip anything that already exists in HOME (container-isolated dotfiles,
    # previously created links, etc.) to avoid clobbering them.
    if [ -e "$_dest" ] || [ -L "$_dest" ]; then
      continue
    fi
    ln -s "$_entry" "$_dest" 2>/dev/null || true
  done
  # Ensure the repo's .npmrc lands at ~/.npmrc (the user-level npm/pnpm config
  # location) so the private @igara registry + auth token are picked up.
  # This is redundant with the loop above but kept explicit to guarantee it.
  if [ -f "$_igara_src/.npmrc" ] && [ ! -e "$HOME/.npmrc" ]; then
    ln -s "$_igara_src/.npmrc" "$HOME/.npmrc" 2>/dev/null || true
  fi
fi
unset _igara_src _entry _name _dest
case "$-" in
  *i*)
    if [ -n "$SSH_CONNECTION" ] && [ "$PWD" = "/" ]; then
      cd "$HOME" 2>/dev/null || true
    fi
    ;;
esac
EOF

EXPOSE 22 3000 3001
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
