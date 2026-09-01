BUILDER_IMAGE=quay.io/centos-bootc/bootc-image-builder:latest

BUILD_TIMESTAMP := $(shell date +%Y%m%dT%H%M%S)
OS_STRING=$(shell sed -n 's/^FROM .*\/\([^@ ]*\).*/\1/p' Containerfile | tail -1)

CONTAINER_TAG=quay.io/elliot_gustafsson/$(OS_STRING)-$(BUILD_TIMESTAMP)
CONTAINER_TAG_NVIDIA=quay.io/elliot_gustafsson/$(OS_STRING)-nvidia-$(BUILD_TIMESTAMP)
ISO_TAG=quay.io/elliot_gustafsson/$(OS_STRING)-iso

AUTH_FILE := $(shell \
	if [ -f "$(HOME)/.docker/config.json" ]; then echo "$(HOME)/.docker/config.json"; \
	elif [ -f "$(HOME)/.config/containers/auth.json" ]; then echo "$(HOME)/.config/containers/auth.json"; \
	elif [ -f "/run/user/$$(id -u)/containers/auth.json" ]; then echo "/run/user/$$(id -u)/containers/auth.json"; \
	elif [ -f "/run/containers/0/auth.json" ]; then echo "/run/containers/0/auth.json"; \
	fi \
)
AUTH_FLAG := $(if $(AUTH_FILE),--authfile $(AUTH_FILE),)

print-tags:
	@echo $(CONTAINER_TAG)
	@echo $(DISK_TAG)

build: build-image build-disk-file

build-iso: build-image build-iso build-iso-image

# release: build-image image-push-container image-sync-container build-disk-file build-disk-image image-push-disk

# sudo bootc switch --transport containers-storage localhost/my-custom-os:latest

build-image:
	sudo podman build --pull --network=host -t $(CONTAINER_TAG) --build-context home=../../home --build-context repo=../.. -f Containerfile .

build-disk-file:
	mkdir -p build-output .osbuild-store
	rm -rf build-output/qcow2
	sudo podman pull $(BUILDER_IMAGE)
	sudo podman run --rm -it --privileged --pull=never \
		--security-opt label=type:unconfined_t \
		-v $$(pwd)/build-output:/output \
		-v $$(pwd)/.osbuild-store:/store \
		-v $$(pwd)/config.toml:/config.toml \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
			--type qcow2 \
			--rootfs btrfs \
			--chown "$$(id -u):$$(id -g)" \
			--config /config.toml \
			--output /output \
			$(CONTAINER_TAG)

build-disk-image:
	sudo podman build --build-arg FILE_PATH=build-output/qcow2/disk.qcow2 \
		-f ../../common/Containerfile.disk .

build-iso:
	mkdir -p build-output .osbuild-store
	rm -rf build-output/bootiso
	sudo podman pull $(BUILDER_IMAGE)
	sudo podman run --rm -it --privileged --pull=never \
		--security-opt label=type:unconfined_t \
		-v $$(pwd)/build-output:/output \
		-v $$(pwd)/.osbuild-store:/store \
		-v $$(pwd)/config.toml:/config.toml \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
			--type anaconda-iso \
			--rootfs btrfs \
			--chown "$$(id -u):$$(id -g)" \
			--config /config.toml \
			--output /output \
			$(CONTAINER_TAG)

build-iso-image:
	sudo podman build --build-arg FILE_PATH=build-output/bootiso/install.iso \
		-t $(ISO_TAG) \
		-f Containerfile.disk .

############# Build nvidia things #############

unlock-mok:
	mkdir -p mok
	openssl enc -d -aes-256-cbc -pbkdf2 -in mok/MOK.key.enc -out mok/MOK.key
	chmod 600 mok/MOK.key
	@echo "MOK key decrypted to mok/MOK.key"

build-nvidia: build-image-nvidia build-disk-file-nvidia
build-iso-nvidia: build-image-nvidia build-iso-file-nvidia build-iso-image-nvidia

build-image-nvidia: build-image
	@if [ ! -f "mok/MOK.key" ]; then \
		echo "MOK key missing! Run 'make unlock-mok' first."; exit 1; \
	fi
	sudo podman build --network=host -t $(CONTAINER_TAG_NVIDIA) \
		--secret id=mok_key,src=mok/MOK.key \
		--build-arg BASE_IMAGE=$(CONTAINER_TAG) \
		-f Containerfile.nvidia .

build-disk-file-nvidia:
	mkdir -p build-output/nvidia .osbuild-store
	rm -rf build-output/nvidia/qcow2
	sudo podman run --rm -it --privileged --pull=never \
		--security-opt label=type:unconfined_t \
		-v $$(pwd)/build-output/nvidia:/output \
		-v $$(pwd)/.osbuild-store:/store \
		-v $$(pwd)/config.toml:/config.toml \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
			--type qcow2 \
			--rootfs btrfs \
			--chown "$$(id -u):$$(id -g)" \
			--config /config.toml \
			--output /output \
			$(CONTAINER_TAG_NVIDIA)

build-iso-file-nvidia:
	mkdir -p build-output/nvidia .osbuild-store
	rm -rf build-output/nvidia/bootiso
	sudo podman run --rm -it --privileged --pull=never \
		--security-opt label=type:unconfined_t \
		-v $$(pwd)/build-output/nvidia:/output \
		-v $$(pwd)/.osbuild-store:/store \
		-v $$(pwd)/config.toml:/config.toml \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BUILDER_IMAGE) \
			--type anaconda-iso \
			--rootfs btrfs \
			--chown "$$(id -u):$$(id -g)" \
			--config /config.toml \
			--output /output \
			$(CONTAINER_TAG_NVIDIA)

build-iso-image-nvidia:
	sudo podman build --build-arg FILE_PATH=build-output/nvidia/bootiso/install.iso \
		-t $(ISO_TAG_NVIDIA) \
		-f Containerfile.disk .

########################################

image-push-container:
	sudo podman push $(AUTH_FLAG) $(CONTAINER_TAG)

image-sync-container:
	sudo podman pull $(AUTH_FLAG) $(CONTAINER_TAG)

image-push-disk:
	sudo podman push $(AUTH_FLAG) $(ISO_TAG)

localrun: ./build-output/qcow2/disk.qcow2
	podman build -t containerfile-localrun -f Containerfile.runner .
	podman run --rm -v "$(shell pwd)/build-output/qcow2:/data" containerfile-localrun qemu-img create -f qcow2 /data/data-disk.qcow2 20G
	podman run --rm -it \
		--device /dev/kvm \
		--network host \
		--privileged \
		--security-opt label=disable \
		--name os-images-localrun \
		-v "$(shell pwd)/build-output/qcow2/disk.qcow2":/data/disk.qcow2 \
		-v "$(shell pwd)/build-output/qcow2/data-disk.qcow2":/data/data-disk.qcow2 \
		-v ~/.ssh:/.ssh:ro \
		containerfile-localrun \
		/usr/libexec/qemu-kvm \
			-m 4G \
			-smp 2 \
			-cpu host \
			-enable-kvm \
			-snapshot \
			-drive file=/data/disk.qcow2,format=qcow2,if=virtio \
			-drive file=/data/data-disk.qcow2,format=qcow2,if=virtio \
			-netdev user,id=net0,hostfwd=tcp::2222-:22 \
			-device virtio-net-pci,netdev=net0 \
			-vga qxl \
            -spice port=5900,addr=0.0.0.0,disable-ticketing=on \
			-serial mon:stdio

localrun-nvidia: ./build-output/nvidia/qcow2/disk.qcow2
	podman build -t containerfile-localrun -f Containerfile.runner .
	podman run --rm -v "$(shell pwd)/build-output/nvidia/qcow2:/data" containerfile-localrun qemu-img create -f qcow2 /data/data-disk.qcow2 20G
	podman run --rm -it \
		--device /dev/kvm \
		--network host \
		--privileged \
		--security-opt label=disable \
		--name os-images-localrun \
		-v "$(shell pwd)/build-output/nvidia/qcow2/disk.qcow2":/data/disk.qcow2 \
		-v "$(shell pwd)/build-output/nvidia/qcow2/data-disk.qcow2":/data/data-disk.qcow2 \
		-v ~/.ssh:/.ssh:ro \
		containerfile-localrun \
		/usr/libexec/qemu-kvm \
			-m 4G \
			-smp 2 \
			-cpu host \
			-enable-kvm \
			-snapshot \
			-drive file=/data/disk.qcow2,format=qcow2,if=virtio \
			-drive file=/data/data-disk.qcow2,format=qcow2,if=virtio \
			-netdev user,id=net0,hostfwd=tcp::2222-:22 \
			-device virtio-net-pci,netdev=net0 \
			-vga qxl \
            -spice port=5900,addr=0.0.0.0,disable-ticketing=on \
			-serial mon:stdio

localrun-view:
	remote-viewer spice://127.0.0.1:5900

### make usb ###
USB ?=
make-boot-media: ./build-output/bootiso/install.iso
	@if [ -z "$(USB)" ] || [ ! -b "$(USB)" ]; then \
		echo "Error: Please specify a valid block device (e.g. make make-boot-media USB=/dev/sda)"; \
		echo "\nAvailable block devices:"; \
		lsblk -d -o NAME,SIZE,TYPE,MODEL,TRAN; \
		exit 1; \
	fi
	@echo "WARNING: All data on $(USB) will be permanently destroyed!"
	@read -p "Are you sure you want to write to $(USB)? (y/N): " confirm && [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]
	sudo dd if=build-output/bootiso/install.iso of=$(USB) bs=4M status=progress oflag=sync
	@echo "Boot media created successfully on $(USB)."
