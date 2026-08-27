import SwiftUI

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
            // Auto clipboard detection banner
            if let clipUrl = clipboard.detectedYouTubeURL, clipUrl != urlText {
                HStack(spacing: 10) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("YouTube Link Detected in Clipboard")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(clipUrl)
                            .font(.system(size: 11))
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
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Paste & Load")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.cyan.opacity(0.2))
                        .foregroundColor(.cyan)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        clipboard.dismissDetection()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // Main Input Box
            HStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                TextField("Paste YouTube video, shorts, or music link here...", text: $urlText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
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
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    if let clip = clipboard.getPasteboardString() {
                        urlText = clip
                        if !urlText.isEmpty {
                            onFetch()
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlColor))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    onFetch()
                }) {
                    HStack(spacing: 6) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "sparkle.magnifyingglass")
                            Text("Inspect")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isFieldFocused ?
                                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                                lineWidth: isFieldFocused ? 1.8 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFieldFocused)
        }
    }
}
