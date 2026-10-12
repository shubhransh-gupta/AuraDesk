# ✦ AuraDesk Pro — 4K Live Desktop, Screen Saver & Lock Screen Engine for macOS

<p align="center">
  <a href="https://github.com/shubhransh-gupta/AuraDesk/releases/latest/download/AuraDesk-macOS.zip">
    <img src="https://img.shields.io/badge/Download-AuraDesk.app_(macOS)-FFFFFF?style=for-the-badge&logo=apple&logoColor=000000" alt="Download AuraDesk.app" />
  </a>
  <a href="https://shubhransh-gupta.github.io/AuraDesk/">
    <img src="https://img.shields.io/badge/Website-Live_4K_Showcase-E2E8F0?style=for-the-badge&logo=safari&logoColor=000000" alt="Live Website" />
  </a>
  <img src="https://img.shields.io/badge/macOS-14.0%2B_(Sonoma_%7C_Sequoia_%7C_Tahoe)-18181B?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/License-MIT_(100%25_Free)-18181B?style=for-the-badge" alt="MIT License" />
</p>

**AuraDesk Pro** is a 100% free, open-source native macOS application built with Swift and SwiftUI that brings **4K 60/240fps live video wallpapers** to all three macOS surfaces simultaneously:

1. **Desktop Wallpaper** (rendered cleanly behind desktop icons and Dock across all connected monitors)
2. **Full-Screen 4K Screen Saver** (with optional macOS Sonoma-style typography clock overlay)
3. **Native macOS Lock Screen** (via zero-reencode `.mov` injection into macOS `com.apple.idleassetsd` with automatic original backup and 1-click restoration)

---

## ✦ Highlights & Features

- **350+ Built-In 4K Ultra HD Wallpapers at the Top**: Open AuraDesk Pro and immediately browse over **350 curated 4K wallpapers** (*Space*, *Dark*, *Abstract*, *Cars*, *Nature*, *Anime*, *Gaming*, and *Apple 240fps 4K Aerials*). No need to hunt for video files—click **`Apply All 3`** on any wallpaper to download and apply it in one click.
- **Instant Local 4K Seeding**: Automatically detects existing 4K 240fps Aerial `.mov` assets on your Mac so you have zero-wait 4K wallpapers ready to apply the moment the app launches.
- **True 3-Surface Synchronization**:
  - **Desktop Engine**: Uses `CGWindowLevelForKey(.desktopWindow)` and hardware-accelerated `AVQueuePlayer` + `AVPlayerLooper` for seamless gapless loops.
  - **Screen Saver Engine**: Full-screen multi-display 4K screen saver with idle timer and Sonoma clock overlay.
  - **Lock Screen Engine**: Remuxes any `.mp4` / `.mov` / `.m4v` into macOS Sonoma / Sequoia / Tahoe's native Aerial pipeline (`/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS/`) while backing up the original Apple asset for 1-click restoration.
- **Zero-Drain Power Management**: Automatically pauses video decoding when your display sleeps or locks, consuming **< 0.3% CPU** via Apple Silicon / Intel hardware video decoding.
- **Custom 4K Video Import & Built-In 4K Synthesizer**: Drag-and-drop any local `.mp4`, `.mov`, or `.m4v` file, or generate a procedural 4K HEVC wallpaper on the fly.

---

## ✦ Quick Install

1. **[Download `AuraDesk-macOS.zip` from the Latest Release](https://github.com/shubhransh-gupta/AuraDesk/releases/latest/download/AuraDesk-macOS.zip)**
2. Unzip and move **`AuraDesk.app`** to your `/Applications` folder.
3. Launch **AuraDesk.app** and click **`Apply All 3`** on any 4K wallpaper in the **Top 4K Wallpapers** workspace.

---

## ✦ Build from Source

Requires macOS 14.0+ and Swift 5.10+ (Xcode or Command Line Tools):

```bash
git clone https://github.com/shubhransh-gupta/AuraDesk.git
cd AuraDesk
./build_app.sh
open AuraDesk.app
```

---

## ✦ Project Architecture

```text
AuraDesk/
├── Package.swift                       # Swift Package Manager manifest (macOS 14+)
├── build_app.sh                        # Release build & .app bundle packager
├── Sources/AuraDesk/
│   ├── AuraDeskApp.swift               # Main Window & MenuBarExtra entry point
│   ├── ContentView.swift               # Pro Black & Silver UI + Aurora Stargazing Canvas
│   ├── CloudCatalogService.swift       # 350+ 4K Catalog, authenticated thumbnail & stream loader
│   ├── WallpaperStore.swift            # State persistence, metadata/thumbnail extractor & 4K synthesizer
│   ├── DesktopWallpaperController.swift# Sub-icon multi-monitor AVQueuePlayer desktop engine
│   ├── ScreenSaverController.swift     # Fullscreen 4K idle screen saver with Sonoma clock
│   ├── LockScreenManager.swift         # macOS idleassetsd Lock Screen injector & backup manager
│   ├── Models.swift                    # Data models for local & remote 4K wallpapers
│   └── Resources/
│       └── curated_4k_catalog.json     # Bundled 4K Ultra HD wallpaper catalog
└── docs/
    ├── index.html                      # Live GitHub Pages marketing & 4K preview showcase
    └── assets/                         # Monochrome 3D hardware renders & real 4K video previews
```

---

## ✦ License

Released under the **MIT License**. 100% Free & Open Source forever.
