define MOZILLA_REPO
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
endef
export MOZILLA_REPO

define MOZILLA_PREFS
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000

Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
endef
export MOZILLA_PREFS

install-firefox:
	@if command -v snap &>/dev/null && snap list firefox &>/dev/null; then \
		sudo snap remove firefox; \
	fi
	sudo install -d -m 0755 /etc/apt/keyrings
	wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc
	echo "$$MOZILLA_REPO" | sudo tee /etc/apt/sources.list.d/mozilla.sources > /dev/null
	echo "$$MOZILLA_PREFS" | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
	sudo apt update
	sudo apt install -y firefox

cleanup:
	sudo apt autoremove --purge -y && sudo apt clean

install-things:
	sudo apt update && sudo apt install -y \
    gcc \
    clang \
    lld \
    llvm \
    clang-tools \
    vim \
    git \
    ripgrep \
    fzf \
    jq \
    make \
    wget \
    nmap \
    htop \
    ncdu \
    dnsutils \
    whois \
    nvtop \
    less \
    man-db \
    manpages \
    bash-completion \
    podman \
    podman-docker \
    unzip \
    flatpak \
    wl-clipboard \
    xclip \
    pciutils \
    usbutils \
    lsof \
    rsync \
    fastfetch \
    fd-find \
    p7zip \
    p7zip-full \
    zstd && \
	sudo apt clean
