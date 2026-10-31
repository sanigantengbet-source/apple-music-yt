#!/usr/bin/env bash
set -e

echo "=============================================="
echo "  Apple Music YT (Rust + Dart) Build Script   "
echo "=============================================="

# Check for Rust
if ! command -v cargo &> /dev/null; then
    echo "[!] Cargo / Rust not found in PATH."
    echo "    To install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "[!] Flutter not found in PATH."
    echo "    Please ensure Flutter SDK is installed and added to PATH."
fi

# 1. Build Rust Native Dynamic Library (if cargo-ndk is installed)
if command -v cargo-ndk &> /dev/null; then
    echo "[+] Building Rust native dynamic library for Android ABIs..."
    cd native
    cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -o ../android/app/src/main/jniLibs build --release
    cd ..
else
    echo "[*] cargo-ndk not detected. The app includes a pure-Dart InnerTube high-performance"
    echo "    fallback engine that connects directly to YouTube Music API."
fi

# 2. Get Flutter Dependencies
echo "[+] Fetching Flutter packages..."
flutter pub get

# 3. Build APK
echo "[+] Building release APK..."
flutter build apk --release

echo "=============================================="
echo "  Build Completed Successfully!               "
echo "  APK output: build/app/outputs/flutter-apk/app-release.apk"
echo "=============================================="
