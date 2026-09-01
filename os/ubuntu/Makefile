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

install-ghostty:
	sudo apt update && sudo apt install -y \
	    libgtk-4-1 \
	    libadwaita-1-0
	mkdir -p /tmp/ghostty-out
	podman build -o /tmp/ghostty-out -f Containerfile.ghostty-builder .

	sudo chown -R root:root /tmp/ghostty-out
	sudo find /tmp/ghostty-out -type d -exec chmod 755 {} +
	sudo find /tmp/ghostty-out/share -type f -exec chmod 644 {} +
	sudo find /tmp/ghostty-out/bin -type f -exec chmod 755 {} +
	sudo find /tmp/ghostty-out/lib -type f -exec chmod 755 {} +

	sudo cp -a --remove-destination /tmp/ghostty-out/bin/* /usr/bin/
	sudo cp -a --remove-destination /tmp/ghostty-out/share/* /usr/share/
	sudo cp -a --remove-destination /tmp/ghostty-out/lib/* /usr/lib/
	sudo rm -rf /tmp/ghostty-out

	sudo ldconfig
	sudo update-desktop-database /usr/share/applications
	sudo gtk4-update-icon-cache -f -t -q /usr/share/icons/hicolor

cleanup:
	sudo apt autoremove --purge -y && sudo apt clean

install-things:
	sudo apt update && sudo apt install -y \
    gnome-shell-extension-manager \
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
