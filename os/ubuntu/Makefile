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
		sudo snap remove firefox || true; \
	fi
	sudo install -d -m 0755 /etc/apt/keyrings
	wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
	sudo chmod 644 /etc/apt/keyrings/packages.mozilla.org.asc
	echo "$$MOZILLA_REPO" | sudo tee /etc/apt/sources.list.d/mozilla.sources > /dev/null
	echo "$$MOZILLA_PREFS" | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
	sudo apt update
	sudo apt install -y --allow-downgrades firefox

UBUNTU_VERSION ?= $(shell . /etc/os-release && echo "$$VERSION_ID")
ifeq ($(UBUNTU_VERSION),24.04)
ZIG_VERSION ?= 0.15.2
GHOSTTY_VERSION ?= 1.3.1
else
ZIG_VERSION ?= 0.17.0
GHOSTTY_VERSION ?= 1.4.0
endif

install-ghostty:
	@test -n "$(UBUNTU_VERSION)" || (echo "UBUNTU_VERSION is not set" >&2; exit 1)
	sudo apt update && sudo apt install -y \
	    libgtk-4-1 \
	    libadwaita-1-0
	mkdir -p /tmp/ghostty-out
	podman build \
	    --build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) \
	    --build-arg ZIG_VERSION=$(ZIG_VERSION) \
	    --build-arg GHOSTTY_VERSION=$(GHOSTTY_VERSION) \
	    -o /tmp/ghostty-out -f Containerfile.ghostty-builder .

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
    fd-find \
    p7zip \
    p7zip-full \
    ffmpeg \
    libavcodec-extra \
    zstd && \
	sudo apt clean

install-hidetopbar:
	GNOME_VER=$$(gnome-shell --version | awk '{print $$3}' | cut -d. -f1) && \
	UUID="hidetopbar@mathieu.bidon.ca" && \
	EXT_DIR="$(HOME)/.local/share/gnome-shell/extensions/$${UUID}" && \
	PK=$$(curl -fsSL --connect-timeout 10 --max-time 20 "https://extensions.gnome.org/extension-info/?uuid=$${UUID}" | jq -r ".shell_version_map[\"$${GNOME_VER}\"].pk") && \
	curl -fsSL --connect-timeout 10 --max-time 30 "https://extensions.gnome.org/download-extension/$${UUID}.shell-extension.zip?version_tag=$${PK}" -o /tmp/htb.zip && \
	rm -rf "$${EXT_DIR}" && mkdir -p "$${EXT_DIR}" && \
	unzip -qo /tmp/htb.zip -d "$${EXT_DIR}/" && \
	rm -f /tmp/htb.zip && \
	glib-compile-schemas "$${EXT_DIR}/schemas/" && \
	(timeout 5 gnome-extensions enable "$${UUID}" 2>/dev/null || true)

configure-desktop:
	sudo install -d -m 0755 /etc/dconf/profile /etc/dconf/db/local.d
	@if [ ! -f /etc/dconf/profile/user ]; then \
		sudo install -m 0644 resources/etc/dconf/profile/user /etc/dconf/profile/user; \
	elif ! grep -q '^system-db:local$$' /etc/dconf/profile/user; then \
		echo "system-db:local" | sudo tee -a /etc/dconf/profile/user > /dev/null; \
	fi
	sudo install -m 0644 resources/etc/dconf/db/local.d/00-extensions /etc/dconf/db/local.d/00-extensions
	sudo install -m 0644 resources/etc/dconf/db/local.d/02-desktop /etc/dconf/db/local.d/02-desktop
	sudo touch /etc/dconf/db/local.d
	sudo dconf update
