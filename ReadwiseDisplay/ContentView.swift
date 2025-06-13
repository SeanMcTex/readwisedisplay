//
//  ContentView.swift
//  ReadwiseDisplay
//
//  Created by Sean Mc Mains on 5/21/25.
//

import SwiftUI

struct Quote: Equatable {
    let text: String
    let author: String
    let source: String
}

// MARK: - Constants
private struct UserMessages {
    static let enterAPIKey = "Please enter your Readwise API key in Settings."
    static let invalidAPIKey = "API Key is invalid or unauthorized. Please check it in Settings."
    static let unexpectedError = "An unexpected error occurred while fetching your quote."
    static let loading = "Loading quote..."
    static let openSettings = "Open Settings"
}

private struct FontSizing {
    // Base font sizes for macOS (largest screen)
    static let macOSQuoteSize: CGFloat = 90
    static let macOSAuthorSize: CGFloat = 48
    static let macOSSourceSize: CGFloat = 38
    
    // Dynamic sizing ratios relative to screen width
    static let quoteRatio: CGFloat = 0.08  // 8% of screen width
    static let authorRatio: CGFloat = 0.04 // 4% of screen width
    static let sourceRatio: CGFloat = 0.032 // 3.2% of screen width
    static let messageRatio: CGFloat = 0.024 // 2.4% of screen width
    static let settingsButtonRatio: CGFloat = 0.024 // 2.4% of screen width
    
    // Minimum and maximum constraints
    static let minQuoteSize: CGFloat = 24
    static let maxQuoteSize: CGFloat = 120
    static let minAuthorSize: CGFloat = 16
    static let maxAuthorSize: CGFloat = 60
    static let minSourceSize: CGFloat = 14
    static let maxSourceSize: CGFloat = 48
    static let minMessageSize: CGFloat = 16
    static let maxMessageSize: CGFloat = 32
    static let minButtonSize: CGFloat = 16
    static let maxButtonSize: CGFloat = 28
}

private struct Layout {
    static let horizontalPaddingRatio: CGFloat = 0.1 // 10% of screen width
    static let settingsButtonPadding: CGFloat = 16
    static let authorSourceSpacing: CGFloat = 8
    static let authorSourceTrailingPadding: CGFloat = 20
    static let authorSourceBottomPadding: CGFloat = 20
    static let messageButtonSpacing: CGFloat = 8
    
    // Bottom padding ratios for quote text
    static let macOSBottomPaddingRatio: CGFloat = 0.2 // 20% of screen height
    static let landscapeBottomPaddingRatio: CGFloat = 0.15 // 15% of screen height
    static let portraitBottomPaddingRatio: CGFloat = 0.18 // 18% of screen height
}

struct ContentView: View {
    @AppStorage("readwiseAPIKey") private var apiKey: String = ""
    @StateObject private var readwise: ReadwiseService
    @State private var displayMessage: String?
    @State private var isShowingSettings: Bool = false

    init() {
        let key = UserDefaults.standard.string(forKey: "readwiseAPIKey") ?? ""
        _readwise = StateObject(wrappedValue: ReadwiseService(apiKey: key))
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _displayMessage = State(initialValue: UserMessages.enterAPIKey)
        }
    }
    
    private let backgroundColors: [Color] = [
        Color(red: 0.1, green: 0.1, blue: 0.2),
        Color(red: 0.15, green: 0.1, blue: 0.15),
        Color(red: 0.1, green: 0.15, blue: 0.2),
        Color(red: 0.12, green: 0.12, blue: 0.18)
    ]
    
    @State private var currentColorIndex = 0
    @AppStorage("quoteRefreshInterval") private var quoteRefreshInterval: Double = 10.0
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let sizing = DynamicSizing(geometry: geometry)
            
            ZStack {
                backgroundColors[currentColorIndex]
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: currentColorIndex)

                #if os(iOS)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isShowingSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: sizing.settingsButtonSize, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(Layout.settingsButtonPadding)
                        }
                    }
                    Spacer()
                }
                .padding(.top, geometry.safeAreaInsets.top)
                #endif

                if let message = displayMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.system(size: sizing.messageSize))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding()
                        #if os(iOS)
                        Button(UserMessages.openSettings) {
                            isShowingSettings = true
                        }
                        .font(.system(size: sizing.messageSize * 0.8))
                        .foregroundColor(.blue)
                        .padding(.top, Layout.messageButtonSpacing)
                        #endif
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let quote = readwise.currentQuote {
                    // Quote Text Container
                    VStack {
                        Spacer()
                        Text(quote.text)
                            .font(.system(size: sizing.quoteSize, weight: .light))
                            .minimumScaleFactor(0.2)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, sizing.horizontalPadding)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, sizing.bottomPadding)
                    .id("quoteView_\(quote.text)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))

                    // Author and Source Container
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: Layout.authorSourceSpacing) {
                                Text("— \(quote.author)")
                                    .font(.system(size: sizing.authorSize, weight: .medium))
                                    .minimumScaleFactor(0.2)
                                    .lineLimit(nil)
                                    .foregroundColor(.white)
                                
                                Text(quote.source)
                                    .font(.system(size: sizing.sourceSize, weight: .regular))
                                    .minimumScaleFactor(0.2)
                                    .lineLimit(nil)
                                    .foregroundColor(.white.opacity(0.8))
                                    .italic()
                            }
                            .padding(.trailing, Layout.authorSourceTrailingPadding)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + Layout.authorSourceBottomPadding)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id("authorSourceView_\(quote.author)_\(quote.source)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))

                } else {
                    VStack {
                        Spacer()
                        Text(UserMessages.loading)
                            .font(.system(size: sizing.messageSize))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .animation(.easeInOut(duration: 1.5), value: readwise.currentQuote)
            .animation(.easeInOut, value: displayMessage)
            #if os(iOS)
            .sheet(isPresented: $isShowingSettings) {
                NavigationView {
                    SettingsView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    isShowingSettings = false
                                }
                            }
                        }
                }
            }
            #endif
            .task {
                await fetchQuoteAndUpdateState()
            }
            .onTapGesture {
                Task {
                    await fetchQuoteAndUpdateState()
                }
            }
            .onReceive(timer) { _ in
                Task {
                    await fetchQuoteAndUpdateState()
                }
            }
            .onChange(of: apiKey) { _, newKey in
                let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
                readwise.updateApiKey(trimmedKey)
                if trimmedKey.isEmpty {
                    displayMessage = UserMessages.enterAPIKey
                    readwise.currentQuote = nil
                    timer.upstream.connect().cancel()
                } else {
                    displayMessage = nil
                    self.timer.upstream.connect().cancel()
                    self.timer = Timer.publish(every: quoteRefreshInterval, on: .main, in: .common).autoconnect()
                    Task {
                        await fetchQuoteAndUpdateState()
                    }
                }
            }
            .onChange(of: quoteRefreshInterval) { _, newValue in
                self.timer.upstream.connect().cancel()
                self.timer = Timer.publish(every: newValue, on: .main, in: .common).autoconnect()
            }
        }
    }

    private func fetchQuoteAndUpdateState() async {
        let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedApiKey.isEmpty {
            displayMessage = UserMessages.enterAPIKey
            readwise.currentQuote = nil
            return
        }

        if displayMessage != nil && !trimmedApiKey.isEmpty {
             displayMessage = nil
        }

        do {
            try await readwise.fetchRandomQuote()
            if readwise.currentQuote != nil {
                displayMessage = nil
            }
            currentColorIndex = (currentColorIndex + 1) % backgroundColors.count
        } catch let rwError as ReadwiseError {
            switch rwError {
            case .apiKeyMissing:
                displayMessage = UserMessages.enterAPIKey
            case .apiKeyInvalid:
                displayMessage = UserMessages.invalidAPIKey
            default:
                displayMessage = rwError.localizedDescription
            }
            readwise.currentQuote = nil
        } catch {
            displayMessage = UserMessages.unexpectedError
            readwise.currentQuote = nil
        }
    }
}

// MARK: - Dynamic Sizing Helper
private struct DynamicSizing {
    let geometry: GeometryProxy
    
    var isLandscape: Bool {
        geometry.size.width > geometry.size.height
    }
    
    var screenWidth: CGFloat {
        geometry.size.width
    }
    
    var screenHeight: CGFloat {
        geometry.size.height
    }
    
    // Calculate font sizes dynamically based on screen dimensions
    var quoteSize: CGFloat {
        #if os(macOS)
        return FontSizing.macOSQuoteSize
        #else
        let dynamicSize = screenWidth * FontSizing.quoteRatio
        return max(FontSizing.minQuoteSize, min(FontSizing.maxQuoteSize, dynamicSize))
        #endif
    }
    
    var authorSize: CGFloat {
        #if os(macOS)
        return FontSizing.macOSAuthorSize
        #else
        let dynamicSize = screenWidth * FontSizing.authorRatio
        return max(FontSizing.minAuthorSize, min(FontSizing.maxAuthorSize, dynamicSize))
        #endif
    }
    
    var sourceSize: CGFloat {
        #if os(macOS)
        return FontSizing.macOSSourceSize
        #else
        let dynamicSize = screenWidth * FontSizing.sourceRatio
        return max(FontSizing.minSourceSize, min(FontSizing.maxSourceSize, dynamicSize))
        #endif
    }
    
    var messageSize: CGFloat {
        let dynamicSize = screenWidth * FontSizing.messageRatio
        return max(FontSizing.minMessageSize, min(FontSizing.maxMessageSize, dynamicSize))
    }
    
    var settingsButtonSize: CGFloat {
        let dynamicSize = screenWidth * FontSizing.settingsButtonRatio
        return max(FontSizing.minButtonSize, min(FontSizing.maxButtonSize, dynamicSize))
    }
    
    var horizontalPadding: CGFloat {
        screenWidth * Layout.horizontalPaddingRatio
    }
    
    var bottomPadding: CGFloat {
        #if os(macOS)
        return screenHeight * Layout.macOSBottomPaddingRatio
        #else
        let ratio = isLandscape ? Layout.landscapeBottomPaddingRatio : Layout.portraitBottomPaddingRatio
        return screenHeight * ratio
        #endif
    }
}

#Preview {
    ContentView()
}
