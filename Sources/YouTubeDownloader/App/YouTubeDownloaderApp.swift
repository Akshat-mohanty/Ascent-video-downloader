import SwiftUI
import AppKit

@main
struct YouTubeDownloaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 720, idealWidth: 800, maxWidth: 1000, minHeight: 600, idealHeight: 680, maxHeight: 900)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Download") {
                Button("Paste and Fetch") {
                    if let clip = ClipboardObserver.shared.getPasteboardString() {
                        ClipboardObserver.shared.detectedYouTubeURL = clip
                    }
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
