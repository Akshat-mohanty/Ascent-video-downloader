# AetherTube - Native macOS YouTube Downloader 🎬✨

A high-performance, aesthetic native macOS application built with **SwiftUI**, **yt-dlp**, and **FFmpeg** designed to download YouTube videos in the highest possible video and audio quality with seamless multiplexing.

---

## 🌟 Key Features

- **🚀 Maximum Quality Video + Audio Muxing**: Automatically extracts and merges the highest video resolution (4K UHD 2160p, 2K 1440p, 1080p Full HD) with the highest audio bitrate stream via `ffmpeg` into a clean `.mp4` without re-encoding loss.
- **✨ Aesthetic macOS Design**: Glassmorphism UI using `.ultraThinMaterial`, vibrant gradients, fluid SwiftUI spring animations, and dark/light mode compatibility.
- **📋 Smart Clipboard Detection**: Detects YouTube URLs copied to your clipboard and offers an instant 1-click **"Paste & Load"** badge.
- **🖼 Rich Video Previews**: Shows video title, channel, duration badge, view count, and available resolution badges.
- **⚡️ Live Real-Time Metrics**: Circular animated progress ring, shimmering download bar, live download speed (`MB/s`), file size progress (`MB / MB`), and ETA countdown.
- **🎛 Format Presets**:
  - 🌟 **Best Quality (Video + Audio)** (Default highest possible)
  - 🎬 **4K Ultra HD (2160p)**
  - 🎬 **2K Quad HD (1440p)**
  - 🎬 **Full HD (1080p)**
  - 🎬 **HD (720p)**
  - 🎵 **Audio Only (MP3 320kbps)**
  - 🎵 **Audio Only (M4A / AAC)**
- **📁 History & Finder Integration**: Past downloads list with 1-click "Play in QuickTime" and "Reveal in Finder".
- **⚙️ Configurable Preferences**: Custom download directory and engine binary paths.

---

## 🚀 How to Run

### Option 1: Launch the Built `.app` (Recommended)
You can directly open the packaged native application:
```bash
open "AetherTube.app"
```
Or double-click **`AetherTube.app`** in Finder and drag it into your `/Applications` folder or macOS Dock!

### Option 2: Rebuild Anytime
```bash
./build_app.sh
```

### Option 3: Run via Swift CLI
```bash
swift run
```

---

## 🛠 Dependencies

AetherTube automatically resolves `yt-dlp` and `ffmpeg` from Homebrew or standard system paths:
- `yt-dlp` (`/opt/homebrew/bin/yt-dlp` or `/usr/local/bin/yt-dlp`)
- `ffmpeg` (`/opt/homebrew/bin/ffmpeg` or `/usr/local/bin/ffmpeg`)

If you ever need to install or update them:
```bash
brew install yt-dlp ffmpeg
```
