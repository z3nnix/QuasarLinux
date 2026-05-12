#!/bin/sh

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root. Use: su -c \"$0\""
    exit 1
fi

pacman -Sy --noconfirm wget
pacman -Sy --noconfirm ruby
pacman -Sy --noconfirm git

cd /

# Backup original os-release if it exists
if [ -f /etc/os-release ]; then
    echo ":: Backing up /etc/os-release to /etc/os-release.backup"
    cp /etc/os-release /etc/os-release.backup
fi

# Clean and prepare for Bedrock hijack by removing distro-specific os-release
echo ":: Cleaning /etc/os-release before Bedrock hijack"
cat > /etc/os-release <<'EOF'

EOF

echo ":: Downloading Bedrock Linux..."
wget https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.31/bedrock-linux-0.7.31-x86_64.sh

echo ":: Running Bedrock hijack..."
sh bedrock-linux-0.7.31-x86_64.sh --hijack

# Wait for hijack to complete and filesystem to be ready
sleep 2

# Update both os-release files
echo ":: Updating os-release files with QuasarLinux branding..."
cat > /etc/os-release <<'EOF'
NAME="QuasarLinux"
PRETTY_NAME="QuasarLinux"
BUILD_ID=rolling
ID=quasar
ID_LIKE="quasar"
HOME_URL="https://z3nnix.github.io/quasarlinux"
SUPPORT_URL="https://github.com/z3nnix/quasarlinux"
BUG_REPORT_URL="https://github.com/z3nnix/quasarlinux/issues"
EOF

# Copy to Bedrock's etc if directory exists
if [ -d /bedrock/etc ]; then
    cp /etc/os-release /bedrock/etc/os-release
    echo ":: Copied os-release to /bedrock/etc/"
fi

# Configure bedrock.conf - change timeout from 30 to 0
if [ -f /bedrock/etc/bedrock.conf ]; then
    echo ":: Configuring bedrock.conf (setting timeout=0)..."
    if grep -q "^timeout" /bedrock/etc/bedrock.conf; then
        sed -i 's/^timeout.*/timeout = 0/' /bedrock/etc/bedrock.conf
    else
        echo "timeout = 0" >> /bedrock/etc/bedrock.conf
    fi
    echo ":: bedrock.conf updated successfully"
elif [ -f /etc/bedrock.conf ]; then
    # Fallback in case bedrock.conf is elsewhere
    echo ":: Configuring /etc/bedrock.conf (setting timeout=0)..."
    if grep -q "^timeout" /etc/bedrock.conf; then
        sed -i 's/^timeout.*/timeout = 0/' /etc/bedrock.conf
    else
        echo "timeout = 0" >> /etc/bedrock.conf
    fi
    echo ":: bedrock.conf updated successfully"
else
    echo ":: Warning: bedrock.conf not found. Timeout may need manual configuration"
fi

echo ":: Bedrock has been setup successfully."

git clone https://github.com/z3nnix/quasarlinux /usr/src/
mv /usr/src/qsr/qsr /usr/bin/qsr
chmod +x /usr/bin/qsr

echo ":: QuasarLinux has been installed successfully. Please reboot your PC"
