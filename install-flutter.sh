#!/bin/bash
# Quick Flutter SDK download for testing

FLUTTER_VERSION="stable"
FLUTTER_DIR="/opt/flutter"

if [ -d "$FLUTTER_DIR" ]; then
    echo "Flutter already installed at $FLUTTER_DIR"
    export PATH="$FLUTTER_DIR/bin:$PATH"
    flutter doctor --version
    exit 0
fi

echo "Downloading Flutter SDK..."
cd /tmp
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -O flutter.tar.xz

if [ $? -ne 0 ]; then
    echo "Failed to download Flutter"
    exit 1
fi

echo "Extracting Flutter SDK..."
tar xf flutter.tar.xz -C /opt/

export PATH="/opt/flutter/bin:$PATH"
flutter doctor --version
