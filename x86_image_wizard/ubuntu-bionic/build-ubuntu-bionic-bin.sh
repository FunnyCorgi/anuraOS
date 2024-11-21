#!/usr/bin/env bash
set -veu

# good for debugging
pause() {
    while read -r -t 0.001; do :; done
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

IMAGES="$(dirname "$0")"/../../build/x86images
OUT_ROOTFS_TAR="$IMAGES"/ubuntu-bionic-rootfs.tar
OUT_ROOTFS_BIN="$IMAGES"/ubuntu-bionic-rootfs.bin
OUT_ROOTFS_MNT="$IMAGES"/ubuntu-bionic-rootfs.mntpoint
CONTAINER_NAME=ubuntu-bionic-full
IMAGE_NAME=i386/ubuntu:bionic-20220301

rm -rf "$IMAGES/ubuntu-bionic-boot" || :
rm -rf "$IMAGES/ubuntu-bionic-rootfs" || :
rm -rf $OUT_ROOTFS_BIN || :
cp ../xfrog.sh .
cp ../xsetrandr.sh .
cp -r ../anuramouse .
cp ../anura-run .
cd ../epoxy/server; RUSTFLAGS="-C target-feature=+crt-static" cargo +nightly b -F twisp -r --target i686-unknown-linux-gnu; cp ../target/i686-unknown-linux-gnu/release/epoxy-server ../../ubuntu-bionic/;
cd ../../ubuntu-bionic;

mkdir -p "$IMAGES"
docker build . --platform linux/386 --rm --tag "$IMAGE_NAME"
docker rm "$CONTAINER_NAME" || true
docker create --platform linux/386 -t -i --name "$CONTAINER_NAME" "$IMAGE_NAME" bash

docker export "$CONTAINER_NAME" > "$OUT_ROOTFS_TAR"
dd if=/dev/zero "of=$OUT_ROOTFS_BIN" bs=512M count=2

loop=$(sudo losetup -f)
sudo losetup -P "$loop" "$OUT_ROOTFS_BIN"
sudo mkfs.ext4 "$loop"
mkdir -p "$OUT_ROOTFS_MNT"
sudo mount "$loop" "$OUT_ROOTFS_MNT"

sudo tar -xf "$OUT_ROOTFS_TAR" -C "$OUT_ROOTFS_MNT"
sudo rm -f "$OUT_ROOTFS_MNT/.dockerenv"
sudo cp resolv.conf "$OUT_ROOTFS_MNT/etc/resolv.conf"
sudo cp hostname "$OUT_ROOTFS_MNT/etc/hostname"

sudo cp -r "$OUT_ROOTFS_MNT/boot" "$IMAGES/ubuntu-bionic-boot"
sudo umount "$loop"
sudo losetup -d "$loop"
rm "$OUT_ROOTFS_TAR"
rm -rf "$OUT_ROOTFS_MNT"
rm anura-run
rm xfrog.sh
rm xsetrandr.sh
rm epoxy-server
rm -rf anuramouse

echo "done! created"
sudo chown -R $USER:$USER $IMAGES/ubuntu-bionic-boot
cd "$IMAGES"
mkdir -p ubuntu-bionic-rootfs
split -b50M ubuntu-bionic-rootfs.bin ubuntu-bionic-rootfs/
cd ../
find x86images/ubuntu-bionic-rootfs/* | jq -Rnc "[inputs]"
