#!/bin/sh

CHROOT_DIR="rootfs"

doas mount --bind /dev "$CHROOT_DIR/dev"
doas mount --bind /proc "$CHROOT_DIR/proc"
doas mount --bind /sys "$CHROOT_DIR/sys"
doas mount -t devpts devpts "$CHROOT_DIR/dev/pts"

doas cp /etc/resolv.conf "$CHROOT_DIR/etc/resolv.conf"

doas chroot "$CHROOT_DIR" /bin/bash

