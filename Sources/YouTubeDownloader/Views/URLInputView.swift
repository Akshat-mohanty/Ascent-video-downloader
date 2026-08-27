import SwiftUI
import AppKit

public struct URLInputView: View {
    @Binding public var urlText: String
    public let isLoading: Bool
    public let onFetch: () -> Void
    public let onPasteAndFetch: () -> Void

    @ObservedObject private var clipboard = ClipboardObserver.shared
    @FocusState private var isFieldFocused: Bool

    public init(
        urlText: Binding<String>,
        isLoading: Bool,
        onFetch: @escaping () -> Void,
        onPasteAndFetch: @escaping () -> Void
    ) {
        self._urlText = urlText
        self.isLoading = isLoading
        self.onFetch = onFetch
        self.onPasteAndFetch = onPasteAndFetch
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Main Input Container Card
            VStack(alignment: .leading, spacing: 14) {
                // Header inside the card: Label + Paste Button
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.primary.opacity(0.6))

                        Text("YOUTUBE VIDEO LINK")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.primary.opacity(0.55))
                            .tracking(0.8)
                    }

                    Spacer()

                    // Aesthetic Paste Button (matching screenshot design)
                    Button(action: {
                        if let clip = clipboard.getPasteboardString(), !clip.isEmpty {
                            urlText = clip
                            clipboard.dismissDetection()
                            onPasteAndFetch()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                            Text("Paste")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color.primary.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Main Input Row: Textfield + Action Button
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        TextField("https://www.youtube.com/watch?v=...", text: $urlText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .tint(.white)
                            .accentColor(.white)
                            .foregroundColor(.primary)
                            .focused($isFieldFocused)
                            .onSubmit {
                                if !urlText.isEmpty && !isLoading {
                                    onFetch()
                                }
                            }

                        if !urlText.isEmpty {
                            Button(action: {
                                urlText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.primary.opacity(0.4))
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isFieldFocused ? Color.white.opacity(0.4) : Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    )

                    // Dark Slate Action Button (matching screenshot)
                    Button(action: {
                        onFetch()
                    }) {
                        HStack(spacing: 6) {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 13))
                                Text("Download")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.22, green: 0.22, blue: 0.24))
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }

                // Footer helper note
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("Supports standard videos, shorts, podcasts, and livestreams")
                        .font(.system(size: 11))
                }
                .foregroundColor(Color.primary.opacity(0.45))
                .padding(.top, 2)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)

            // Auto Clipboard Detection Banner if present
            if let clipUrl = clipboard.detectedYouTubeURL, clipUrl != urlText {
                HStack(spacing: 10) {
                    Image(systemName: "link.badge.plus")
                        .foregroundColor(.blue)
                        .font(.system(size: 13))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("YouTube Link in Clipboard")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(clipUrl)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button(action: {
                        urlText = clipUrl
                        clipboard.dismissDetection()
                        onPasteAndFetch()
                    }) {
                        Text("Paste & Load")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        clipboard.dismissDetection()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
