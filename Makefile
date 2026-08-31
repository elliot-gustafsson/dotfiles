set-settings: set-bashrc set-inputrc set-ghostty-settings set-codium-settings

sync-settings: sync-bashrc sync-inputrc sync-ghostty-settings sync-codium-settings

set-bashrc:
	cp home/.bashrc $(HOME)/.bashrc

sync-bashrc:
	cp $(HOME)/.bashrc home/.bashrc

set-inputrc:
	cp home/.inputrc $(HOME)/.inputrc

sync-inputrc:
	cp $(HOME)/.inputrc home/.inputrc

set-ghostty-settings:
	cp home/.config/ghostty/config $(HOME)/.config/ghostty/config

sync-ghostty-settings:
	cp $(HOME)/.config/ghostty/config home/.config/ghostty/config

set-codium-settings:
	cp home/.config/VSCodium/User/keybindings.json $(HOME)/.config/VSCodium/User/keybindings.json
	cp home/.config/VSCodium/User/settings.json $(HOME)/.config/VSCodium/User/settings.json

sync-codium-settings:
	cp $(HOME)/.config/VSCodium/User/keybindings.json home/.config/VSCodium/User/keybindings.json
	cp $(HOME)/.config/VSCodium/User/settings.json home/.config/VSCodium/User/settings.json

save-codium-extensions:
	codium --list-extensions > extra/codium/extensions.txt

install-codium-extensions:
	cat extra/codium/extensions.txt | xargs -n 1 codium --install-extension

### install things ###

generate-ssh-key:
	@if [ -f "$(HOME)/.ssh/id_ed25519" ]; then \
		echo "SSH key already exists at $(HOME)/.ssh/id_ed25519"; \
	else \
		mkdir -p $(HOME)/.ssh && \
		ssh-keygen -t ed25519 -N "" -C "elliot@$$(cat /etc/hostname 2>/dev/null || echo elliot)" -f $(HOME)/.ssh/id_ed25519 && \
		chmod 700 $(HOME)/.ssh && \
		chmod 600 $(HOME)/.ssh/id_ed25519 && \
		chmod 644 $(HOME)/.ssh/id_ed25519.pub && \
		echo "Generated SSH key at $(HOME)/.ssh/id_ed25519:"; \
		cat $(HOME)/.ssh/id_ed25519.pub; \
	fi

KUBECTL_VERSION=v1.33.5
install-kubectl:
	mkdir -p $(HOME)/.local/bin
	wget -O $(HOME)/.local/bin/kubectl https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/linux/amd64/kubectl
	chmod 755 $(HOME)/.local/bin/kubectl

VIRTCTL_VERSION=v1.5.2
install-virtctl:
	mkdir -p $(HOME)/.local/bin
	wget -O $(HOME)/.local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/$(VIRTCTL_VERSION)/virtctl-$(VIRTCTL_VERSION)-linux-amd64
	chmod 755 $(HOME)/.local/bin/virtctl

GO_VERSION=go1.27.0
install-go:
	rm -rf /tmp/go.tar.gz $(HOME)/.local/go
	wget -O /tmp/go.tar.gz https://go.dev/dl/$(GO_VERSION).linux-amd64.tar.gz
	mkdir -p $(HOME)/.local/bin
	tar -C $(HOME)/.local -xzf /tmp/go.tar.gz
	ln -sf $(HOME)/.local/go/bin/go $(HOME)/.local/bin/go
	ln -sf $(HOME)/.local/go/bin/gofmt $(HOME)/.local/bin/gofmt
	rm -f /tmp/go.tar.gz

JSONNET_VERSION=0.22.0
install-jsonnet:
	rm -rf /tmp/go-jsonnet /tmp/go-jsonnet.tar.gz
	wget -O /tmp/go-jsonnet.tar.gz https://github.com/google/go-jsonnet/releases/download/v$(JSONNET_VERSION)/go-jsonnet_$(JSONNET_VERSION)_linux_amd64.tar.gz
	mkdir /tmp/go-jsonnet
	tar -C /tmp/go-jsonnet -xzf /tmp/go-jsonnet.tar.gz
	chmod 755 /tmp/go-jsonnet/jsonnet*
	mv /tmp/go-jsonnet/jsonnet* ~/.local/bin/
	rm -rf /tmp/go-jsonnet /tmp/go-jsonnet.tar.gz

NVIM_VERSION=v0.11.6
install-nvim:
	rm -rf /tmp/nvim.tar.gz $(HOME)/.local/nvim
	wget -O /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/download/$(NVIM_VERSION)/nvim-linux-x86_64.tar.gz
	mkdir -p $(HOME)/.local/bin $(HOME)/.local/nvim
	tar -C $(HOME)/.local/nvim --strip-components=1 -xzf /tmp/nvim.tar.gz
	ln -sf $(HOME)/.local/nvim/bin/nvim $(HOME)/.local/bin/nvim
	rm -f /tmp/nvim.tar.gz

ZIG_VERSION=0.16.0
install-zig:
	rm -rf /tmp/zig.tar.xz $(HOME)/.local/zig
	wget -O /tmp/zig.tar.xz https://ziglang.org/download/$(ZIG_VERSION)/zig-x86_64-linux-$(ZIG_VERSION).tar.xz
	mkdir -p $(HOME)/.local/bin
	tar -C $(HOME)/.local -xf /tmp/zig.tar.xz
	mv $(HOME)/.local/zig-x86_64-linux-$(ZIG_VERSION) $(HOME)/.local/zig
	ln -sf $(HOME)/.local/zig/zig $(HOME)/.local/bin/zig
	rm -f /tmp/zig.tar.xz

RUST_VERSION=1.96.0
install-rust:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain $(RUST_VERSION)

define CODIUM_DESKTOP
[Desktop Entry]
Name=VSCodium
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=$(HOME)/.local/bin/codium %F
Icon=codium
Type=Application
StartupNotify=true
StartupWMClass=codium
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;
endef
export CODIUM_DESKTOP

CODIUM_VERSION=1.126.04524
install-codium:
	rm -rf /tmp/codium.tar.gz $(HOME)/.local/share/vscodium
	wget -O /tmp/codium.tar.gz https://github.com/VSCodium/vscodium/releases/download/$(CODIUM_VERSION)/VSCodium-linux-x64-$(CODIUM_VERSION).tar.gz
	mkdir -p $(HOME)/.local/bin $(HOME)/.local/share/vscodium $(HOME)/.local/share/applications $(HOME)/.local/share/icons/hicolor/512x512/apps
	tar -C $(HOME)/.local/share/vscodium -xzf /tmp/codium.tar.gz
	ln -sf $(HOME)/.local/share/vscodium/bin/codium $(HOME)/.local/bin/codium
	ln -sf $(HOME)/.local/share/vscodium/bin/codium $(HOME)/.local/bin/code
	ln -sf $(HOME)/.local/share/vscodium/resources/app/resources/linux/code.png $(HOME)/.local/share/icons/hicolor/512x512/apps/codium.png
	echo "$$CODIUM_DESKTOP" > $(HOME)/.local/share/applications/codium.desktop
	update-desktop-database $(HOME)/.local/share/applications 2>/dev/null || true
	gtk4-update-icon-cache -f -t -q $(HOME)/.local/share/icons/hicolor 2>/dev/null || true
	rm -f /tmp/codium.tar.gz
	@echo "VSCodium $(CODIUM_VERSION) installed successfully."
