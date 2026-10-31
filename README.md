# Apple Music YT (Rust + Dart)

Aplikasi musik mobile & desktop native dengan UI **identik 100% dengan Apple Music (iOS)**, ditenagai oleh kombinasi performa tinggi **Rust (Native Core)** dan **Dart / Flutter (Cross-Platform UI)**, terintegrasi penuh dengan katalog **YouTube Music**.

Mendukung platform: **Android (APK), iOS, Windows, macOS, dan Linux**.

---

## Fitur Utama

| Fitur | Penjelasan Detail |
| :--- | :--- |
| **Desain Apple Music Asli** | Tipografi ala Apple San Francisco, palet warna *True Dark Pitch Black* (`#000000`), aksen merah Apple Music (`#FA243C`), frosted glassmorphism blur, kartu album bulat dengan dynamic drop shadow. |
| **5 Tab Navigasi Apple Music** | **Dengarkan Sekarang (Listen Now)**, **Telusuri (Browse)**, **Radio (Apple Music 1 Live)**, **Perpustakaan (Library)**, dan **Cari (Search)**. |
| **Floating Mini Player** | Pill melayang di atas tab bar dengan efek kaca blur (`BackdropFilter`), thumbnail artwork, judul & artis, kontrol play/pause & skip, serta scrubber tipis di tepi bawah. |
| **Full Screen Player Dinamis** | Latar belakang gradien blur dinamis yang menyesuaikan warna cover album. Cover album membesar (*scale 1.0*) saat diputar dan mengecil halus (*scale 0.84*) saat jeda persis Apple Music di iPhone. |
| **Lirik Interaktif (Time-Synced Lyrics)** | Lirik bercahaya (*ambient glow*) baris-demi-baris secara real-time. Teks yang sedang dinyanyikan menjadi putih tebal bercahaya, baris lain memudar. Sentuh baris mana saja untuk langsung melompat (*seek*). |
| **Antrean Putar (Up Next)** | Urutkan ulang lagu secara drag-and-drop (`ReorderableListView`), hapus antrean, mode acak (*shuffle*), dan putar berulang (*repeat*). |
| **Pemutaran Latar Belakang (Background Play)** | **Wajib didukung**: Musik tetap berputar saat aplikasi di-minimize atau layar HP mati. Dilengkapi notifikasi kontrol media Android (*MediaStyleNotification*) & iOS *Lock Screen / Control Center* lengkap dengan cover lagu, judul, artis, tombol next/prev, dan seekbar. |
| **Rust Native Core (FFI)** | Modul Rust (`native/`) untuk query InnerTube YouTube Music API, dekoder stream cipher, dan resolusi audio kualitas tinggi (*Opus 160kbps / M4A 128kbps*). |
| **Pure Dart Fallback Engine** | Jika library Rust belum dikompilasi, aplikasi otomatis beralih ke engine Dart murni tanpa kendala dan tanpa crash. |

---

## Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────┐
│                 Apple Music Flutter App                     │
│  (Listen Now · Browse · Radio · Library · Search · Player)  │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
┌──────────────────────────────┐ ┌──────────────────────────────┐
│      Rust Native Core        │ │  AudioService & JustAudio    │
│  (C-FFI: libytmusic_rust.so) │ │   Background Play Service    │
│  - InnerTube Client          │ │  - Lockscreen Controller     │
│  - Stream Cipher Decipher    │ │  - MediaStyle Notification   │
│  - Direct Opus/M4A Extractor │ │  - Headphone Button Receiver │
└──────────────┬───────────────┘ └──────────────┬───────────────┘
               │                                │
               └───────────────┬────────────────┘
                               ▼
               ┌───────────────────────────────┐
               │    YouTube Music CDN & API    │
               │   (Streaming Audio Latar)     │
               └───────────────────────────────┘
```

---

## Struktur Direktori

```
apple_music_yt/
├── lib/
│   ├── main.dart                      # Inisialisasi AudioService & App Theme
│   ├── constants/
│   │   └── apple_music_colors.dart    # Token warna dan gradien Apple Music
│   ├── models/
│   │   ├── song.dart                  # Model Song dengan thumbnail resolusi tinggi
│   │   └── music_models.dart          # Album, Artist, Playlist, LyricsLine
│   ├── services/
│   │   ├── rust_bridge.dart           # FFI bindings ke modul Rust + Dart Fallback
│   │   ├── ytmusic_api_service.dart   # YouTube Music InnerTube Client
│   │   ├── audio_player_service.dart  # Background audio handler (AudioService)
│   │   └── storage_service.dart       # Penyimpanan lokal (Favorit, Riwayat)
│   ├── providers/
│   │   └── music_provider.dart        # State management pemutar & antrean
│   ├── widgets/
│   │   ├── mini_player.dart           # Floating glass mini player
│   │   ├── full_screen_player.dart    # Full player dengan background dinamis
│   │   ├── lyrics_view.dart           # Tampilan lirik realtime bercahaya
│   │   ├── queue_view.dart            # Up Next antrean lagu
│   │   └── apple_shelf.dart           # Carousel horizontal album/lagu
│   └── screens/
│       ├── main_navigation_screen.dart # 5 Tab navigasi Cupertino
│       ├── listen_now_screen.dart     # Dengarkan Sekarang
│       ├── browse_screen.dart         # Telusuri
│       ├── radio_screen.dart          # Radio (Apple Music 1)
│       ├── library_screen.dart        # Koleksi & Riwayat
│       └── search_screen.dart         # Pencarian & Kategori Warna
├── native/                            # Modul Rust C-FFI
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs                     # Ekspor C-FFI (search, stream, ping)
│       ├── ytmusic.rs                 # Client YouTube Music di Rust
│       └── cipher.rs                  # Algoritma decoding signature cipher
├── android/                           # Konfigurasi Foreground Audio Service Android
├── ios/                               # Konfigurasi Background Audio Mode iOS
├── windows/                           # Runner Desktop Windows
├── macos/                             # Runner Desktop macOS
├── linux/                             # Runner Desktop Linux
├── build_apk.sh                       # Script build APK otomatis
└── .github/workflows/
    └── build_release.yml              # CI/CD otomatis kompilasi APK & Desktop
```

---

## Cara Menjalankan & Build APK

### Opsi 1: Build Otomatis via GitHub Actions (Rekomendasi untuk Android/HP)

Jika Anda sedang bekerja di HP atau tidak memiliki Android SDK / JDK 17 terpasang di terminal lokal:

1. Buat repository baru di akun GitHub Anda (misal: `apple-music-yt`).
2. Masukkan dan dorong (push) kode ke GitHub:
   ```bash
   cd /home/sani123/apple_music_yt
   git init -b main
   git add -A
   git commit -m "Initial commit: Apple Music YT Native (Rust & Dart)"
   git remote add origin https://github.com/<username>/apple-music-yt.git
   git push -u origin main
   ```
3. Buka tab **Actions** di GitHub Anda:
   - GitHub Actions akan otomatis mengompilasi Rust, menginstal Flutter, dan menghasilkan file **`app-release.apk`**.
   - Anda tinggal mengunduh file APK dan langsung menginstalnya di HP Anda!

---

### Opsi 2: Jalankan & Build Secara Lokal

#### 1. Kompilasi Modul Rust (Opsional)
```bash
cd /home/sani123/apple_music_yt/native
cargo build --release
```
Untuk mengompilasi `.so` khusus Android:
```bash
cargo install cargo-ndk
cargo ndk -t arm64-v8a -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
```

#### 2. Jalankan Aplikasi Flutter
```bash
cd /home/sani123/apple_music_yt
flutter pub get
flutter run
```

#### 3. Build File APK Siap Pasang
```bash
./build_apk.sh
```
File APK akan berada di:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Konfigurasi Pemutaran Latar Belakang

Aplikasi telah dikonfigurasi dengan izin lengkap untuk pemutaran latar belakang:
- **Android (`AndroidManifest.xml`)**:
  - `FOREGROUND_SERVICE` dan `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (Android 14+ compatible).
  - `MediaStyle` notification dengan media session token aktif.
  - Penanganan tombol headset / tombol bluetooth mobil melalui `MediaButtonReceiver`.
- **iOS (`Info.plist` & `AppDelegate.swift`)**:
  - `UIBackgroundModes`: `audio` dan `fetch`.
  - `AVAudioSession.setCategory(.playback)` otomatis diinisialisasi saat aplikasi dijalankan.
