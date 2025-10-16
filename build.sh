#!/bin/bash

ROOTFS_DIR="rootfs"
TEMP_DIR="/tmp/bootable_iso"
ISO_NAME="quasarlinux-bootable.iso"

echo "Creating /boot/ structure..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"/{boot/grub,proc,sys,dev,run,tmp}

echo "Copy rootfs..."
rsync -a --exclude='/proc' --exclude='/sys' --exclude='/dev' \
      --exclude='/run' --exclude='/tmp' \
      --exclude='/var/tmp/*' \
      --exclude='/var/cache/*' \
      --exclude='/var/log/*' \
      --exclude='*.swp' \
      --exclude='*.tmp' \
      "$ROOTFS_DIR"/ "$TEMP_DIR"/ 2>/dev/null || true

# Check kernel
if [ ! -f "$TEMP_DIR/boot/vmlinuz" ]; then
    echo "Kernel isn't exist. Search in rootfs..."
    
    # Search in rootfs
    KERNEL=$(find "$ROOTFS_DIR" -name "vmlinuz*" -type f ! -name "*.old" | head -1)
    INITRD=$(find "$ROOTFS_DIR" -name "initrd*" -o -name "initramfs*" -type f | head -1)
    
    if [ -n "$KERNEL" ]; then
        echo "Found kernel: $KERNEL"
        cp "$KERNEL" "$TEMP_DIR/boot/vmlinuz"
    else
        echo "❌Kernel isn't exist in rootfs!"
        echo "Avaible files in /boot:"
        ls -la "$ROOTFS_DIR/boot/" 2>/dev/null || echo "/boot isn't exist"
        exit 1
    fi
    
    if [ -n "$INITRD" ]; then
        echo "Found initrd: $INITRD"
        cp "$INITRD" "$TEMP_DIR/boot/initrd.img"
    else
        echo "⚠️ Initrd didn't find, create empty"
        touch "$TEMP_DIR/boot/initrd.img"
    fi
fi

echo "Removing temp files..."
find "$TEMP_DIR" -name "*.swp" -delete 2>/dev/null || true
find "$TEMP_DIR" -name "*.tmp" -delete 2>/dev/null || true
rm -rf "$TEMP_DIR/var/tmp/*" 2>/dev/null || true
rm -rf "$TEMP_DIR/tmp/*" 2>/dev/null || true

echo "Make GRUB config..."
cat > "$TEMP_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=5
set default=0

menuentry "Quasar Linux" {
    linux /boot/vmlinuz root=/dev/sr0 ro quiet
    initrd /boot/initrd.img
}

menuentry "Quasar Linux (single user)" {
    linux /boot/vmlinuz root=/dev/sr0 ro single
    initrd /boot/initrd.img
}
EOF

ls -la "$TEMP_DIR/boot/"

echo "Make ISO..."
grub-mkrescue -o "$ISO_NAME" "$TEMP_DIR"

if [ $? -eq 0 ]; then
    echo "✅ ISOcreated: $ISO_NAME ($(du -h "$ISO_NAME" | cut -f1))"
else
    echo "❌Fault"
    exit 1
fi

rm -rf "$TEMP_DIR"
echo "Succesfull! | qemu-system-x86_64 -cdrom $ISO_NAME -m 2G"
