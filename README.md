![Uploading Screenshot 2026-08-27 at 5.39.52 PM.png…]()


# Ascent - Native macOS YouTube Downloader

A high-performance native macOS application built with SwiftUI, yt-dlp, and FFmpeg designed to download YouTube videos in the highest possible video and audio quality with seamless multiplexing.

---

## Key Features

- **Maximum Quality Video + Audio Muxing**: Automatically extracts and merges the highest video resolution (4K UHD 2160p, 2K 1440p, 1080p Full HD) with the highest audio bitrate stream via FFmpeg into a clean MP4 without re-encoding loss.
- **Aesthetic macOS Design**: Glassmorphism UI using `.ultraThinMaterial`, subtle gradients, fluid SwiftUI spring animations, and dark/light mode compatibility.
- **Smart Clipboard Detection**: Detects YouTube URLs copied to your clipboard and offers an instant one-click "Paste & Load" action.
- **Rich Video Previews**: Shows video title, channel, duration badge, view count, and available resolution badges.
- **Live Real-Time Metrics**: Circular animated progress ring, download bar, live download speed, file size progress, and ETA countdown.
- **Format Presets**:
  - Best Quality (Video + Audio) (Default highest possible)
  - 4K Ultra HD (2160p)
  - 2K Quad HD (1440p)
  - Full HD (1080p)
  - HD (720p)
  - Audio Only (MP3 320kbps)
  - Audio Only (M4A / AAC)
- **History & Finder Integration**: Past downloads list with one-click "Play in QuickTime" and "Reveal in Finder".
- **Configurable Preferences**: Custom download directory and engine binary path settings.

---

## How to Run

### Launch the Built Application
```bash
open "Ascent.app"
```
Or double-click `Ascent.app` in Finder and drag it into your `/Applications` folder or macOS Dock.
---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
