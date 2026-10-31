#!/usr/bin/env bash
set -e

echo "=============================================="
echo "  Apple Music YT (Rust + Dart) Build Script   "
echo "=============================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# 1. Environment Diagnostics
MISSING_TOOLS=0

if ! command -v cargo &> /dev/null; then
    echo "[!] Cargo / Rust not found in PATH."
    echo "    To install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    MISSING_TOOLS=1
fi

if ! command -v flutter &> /dev/null; then
    echo "[!] Flutter SDK not found in PATH."
    echo "    Please install Flutter (>=3.22.0) and export it to PATH."
    MISSING_TOOLS=1
fi

if [ "$MISSING_TOOLS" -ne 0 ] && ! command -v flutter &> /dev/null; then
    echo "[x] Cannot proceed without Flutter. Aborting."
    exit 1
fi

# 2. Build Rust Native Dynamic Library (if cargo & cargo-ndk are available)
if command -v cargo-ndk &> /dev/null; then
    echo "[+] Building Rust native dynamic library for Android ABIs..."
    
    # Auto-detect Android NDK if not explicitly set
    if [ -z "$ANDROID_NDK_HOME" ]; then
        if [ -n "$ANDROID_NDK_LATEST_HOME" ] && [ -d "$ANDROID_NDK_LATEST_HOME" ]; then
            export ANDROID_NDK_HOME="$ANDROID_NDK_LATEST_HOME"
        elif [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME/ndk" ]; then
            export ANDROID_NDK_HOME=$(find "$ANDROID_HOME/ndk" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -n 1)
        fi
    fi

    if [ -n "$ANDROID_NDK_HOME" ] && [ -d "$ANDROID_NDK_HOME" ]; then
        echo "[+] Using Android NDK: $ANDROID_NDK_HOME"
        mkdir -p android/app/src/main/jniLibs
        cd native
        cargo ndk --platform 21 -t arm64-v8a -t armeabi-v7a -t x86_64 -o ../android/app/src/main/jniLibs build --release
        cd ..
        echo "[+] Rust native libraries compiled and placed in android/app/src/main/jniLibs"
    else
        echo "[!] ANDROID_NDK_HOME not found. Rust compilation skipped."
        echo "    Using high-performance pure-Dart InnerTube fallback engine."
    fi
else
    echo "[*] cargo-ndk not detected. The app will use the pure-Dart"
    echo "    InnerTube high-performance engine seamlessly."
fi

# 3. Ensure assets directory exists
mkdir -p assets/images

# 4. Get Flutter Dependencies
echo "[+] Fetching Flutter packages..."
flutter pub get

# 5. Build Release APK
echo "[+] Building release APK..."
flutter build apk --release

# 6. Verify Output
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(stat -c%s "$APK_PATH" 2>/dev/null || stat -f%z "$APK_PATH" 2>/dev/null || echo "OK")
    echo "=============================================="
    echo "  Build Completed Successfully!               "
    echo "  APK output : $APK_PATH"
    echo "  APK size   : $APK_SIZE bytes"
    echo "=============================================="
else
    echo "[!] Build failed: APK not found at $APK_PATH"
    exit 1
fi
