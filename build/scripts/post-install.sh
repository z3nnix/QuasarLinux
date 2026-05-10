#!/bin/sh

cd /
wget https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.31/bedrock-linux-0.7.31-x86_64.sh
sh bedrock-linux-0.7.31-x86_64.sh --hijack

cat > /etc/os-release <<'EOF'
NAME="QuasarLinux"
VERSION="0.1.0"
ID=quasar
ID_LIKE="debian bedrock"
PRETTY_NAME="QuasarLinux 0.1.0"
HOME_URL="https://z3nnix.github.io/quasarlinux"
SUPPORT_URL="https://github.com/z3nnix/quasarlinux
BUG_REPORT_URL="https://github.com/z3nnix/quasarlinux/issues"
EOF

cat > /bedrock/strata/debian/etc/os-release <<'EOF'
NAME="Debian (Quasar stratum)"
VERSION="12 (bookworm)"
ID=debian
PRETTY_NAME="Debian GNU/Linux 12 (bookworm) - Quasar base"
EOF

echo ":: Bedrock has been setup. Please, reboot PC"