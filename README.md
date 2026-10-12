# AuraDesk — Free 4K Live Wallpaper, Screen Saver & Lock Screen for macOS

**AuraDesk** is a 100% free and open-source native macOS engine written in Swift, SwiftUI, and AVFoundation that brings hardware-accelerated **4K 60/240fps live video** to all three macOS surfaces:

1. **Desktop Live Wallpaper** — Plays seamlessly behind desktop icons across all monitors and Spaces (`CGWindowLevelForKey(.desktopWindow)`), automatically pausing when displays sleep or sessions lock.
2. **Native macOS Lock Screen (`idleassetsd`)** — Automatically remuxes your custom 4K video into an Apple-compliant `.mov`, backs up Apple's original `4KSDR240FPS` Aerial file, updates `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`, and injects the 4K video into `/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS/` for genuine Lock Screen motion and slow-mo wake transitions.
3. **4K Screen Saver Engine** — Supports both macOS's native Aerial Screen Saver and a built-in fullscreen 4K Screen Saver overlay with a Sonoma-style clock and idle timer.
4. **Built-In 350+ 4K Cloud Catalog** — Browse, search, and download over **213+ Community 4K UHD Wallpapers** (Space, Supercars, Anime, Nature, Cyberpunk, Dark OLED, Gaming) plus **Apple's 240fps 4K Aerial Streams** directly inside the app with zero paywalls.

---

## Live Marketing Website

- **Marketing Page Source**: [`docs/index.html`](./docs/index.html)

---

## Build & Run from Source

Requirements: macOS 14.0+ (Sonoma, Sequoia, or Tahoe) with Swift 5.9+ / Command Line Tools.

```bash
git clone https://github.com/shubhransh-gupta/AuraDesk.git
cd AuraDesk
chmod +x build_app.sh
./build_app.sh
open AuraDesk.app
```

---

## Key Features

- **Discover 4K Catalog Tab**: Filter by category (`Space`, `Cars`, `Anime`, `Nature`, `Abstract`, `Dark`, `Gaming`, `Heroes`, `Aerial 4K`), search by keyword, and click **Get & Set Desktop** or **All 3** to download and apply in one click.
- **Bring Your Own 4K Video**: Drag-and-drop any `.mp4`, `.mov`, or `.m4v` file into the window.
- **Built-in 4K Procedural Synthesizer**: Click **Synthesize 4K Aurora Sample** to hardware-encode a 4K HEVC `.mov` sample on the spot.
- **One-Click Safe Restore**: Every time AuraDesk overrides a macOS Aerial slot for Lock Screen playback, it backs up the original Apple `.mov` file first so you can restore it anytime with a single click.
- **Menu Bar Quick Controller**: Runs quietly in your macOS menu bar when the main studio window is closed.

---

## License

Released under the **MIT License** — 100% free forever.
