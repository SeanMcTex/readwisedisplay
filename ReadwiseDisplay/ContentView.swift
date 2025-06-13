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

struct ContentView: View {
    // Ensure this apiKey is your valid Readwise API key
    @AppStorage("readwiseAPIKey") private var apiKey: String = ""
    @StateObject private var readwise: ReadwiseService
    @State private var displayMessage: String?
    // @State private var isShowingSettings: Bool = false

    init() {
        let key = UserDefaults.standard.string(forKey: "readwiseAPIKey") ?? ""
        _readwise = StateObject(wrappedValue: ReadwiseService(apiKey: key))
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _displayMessage = State(initialValue: "Please enter your ReadWise API key in Settings.")
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
            let horizontalPaddingForQuote = geometry.size.width * 0.1

            ZStack {
                backgroundColors[currentColorIndex]
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: currentColorIndex)

                /*
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            //isShowingSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                    }
                    Spacer()
                }
                .padding(.top, geometry.safeAreaInsets.top)
                */

                if let message = displayMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let quote = readwise.currentQuote {
                    // Layer 2: Quote Text Container
                    VStack { // This VStack is used for vertical centering and padding
                        Spacer()
                        Text(quote.text)
                            .font(.system(size: 90, weight: .light))
                            .minimumScaleFactor(0.2)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, horizontalPaddingForQuote)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 170) // Reserved space for author/source
                    .id("quoteView_\(quote.text)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))

                    // Layer 3: Author and Source Container
                    VStack { // For bottom-right pinning
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("— \(quote.author)")
                                    .font(.system(size: 48, weight: .medium))
                                    .minimumScaleFactor(0.2)
                                    .lineLimit(nil)
                                    .foregroundColor(.white)
                                
                                Text(quote.source)
                                    .font(.system(size: 38, weight: .regular))
                                    .minimumScaleFactor(0.2)
                                    .lineLimit(nil)
                                    .foregroundColor(.white.opacity(0.8))
                                    .italic()
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id("authorSourceView_\(quote.author)_\(quote.source)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))

                } else { // No specific message, no quote, API key likely present -> Loading state
                    VStack {
                        Spacer()
                        Text("Loading quote...")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .animation(.easeInOut(duration: 1.5), value: readwise.currentQuote)
            .animation(.easeInOut, value: displayMessage) // Animate message changes too
            // .sheet(isPresented: $isShowingSettings) {
            //     SettingsView()
            // }
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
                readwise.updateApiKey(trimmedKey) // Update service's key
                if trimmedKey.isEmpty {
                    displayMessage = "Please enter your ReadWise API key in Settings."
                    readwise.currentQuote = nil // Clear any existing quote
                    timer.upstream.connect().cancel() // Stop timer if no key
                } else {
                    displayMessage = nil // Clear message if key is now present
                    // Restart timer and fetch
                    self.timer.upstream.connect().cancel()
                    self.timer = Timer.publish(every: quoteRefreshInterval, on: .main, in: .common).autoconnect()
                    Task {
                        await fetchQuoteAndUpdateState()
                    }
                }
            }
            .onChange(of: quoteRefreshInterval) { oldValue, newValue in
                print("Timer interval changed to: \(newValue)")
                // Cancel the old timer
                self.timer.upstream.connect().cancel()
                // Start a new timer with the new interval
                self.timer = Timer.publish(every: newValue, on: .main, in: .common).autoconnect()
            }
        }
    }

    private func fetchQuoteAndUpdateState() async {
        let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedApiKey.isEmpty {
            displayMessage = "Please enter your ReadWise API key in Settings."
            readwise.currentQuote = nil
            return
        }

        // Clear previous message before attempting to fetch, but only if API key is present
        if displayMessage != nil && !trimmedApiKey.isEmpty {
             displayMessage = nil
        }

        do {
            try await readwise.fetchRandomQuote()
            // If fetch is successful, currentQuote will be updated by the service,
            // and the UI will react. displayMessage should be nil.
            if readwise.currentQuote != nil { // Ensure message is cleared on success
                displayMessage = nil
            }
            currentColorIndex = (currentColorIndex + 1) % backgroundColors.count
        } catch let rwError as ReadwiseError {
            switch rwError {
            case .apiKeyMissing:
                displayMessage = "Please enter your ReadWise API key in Settings."
            case .apiKeyInvalid:
                displayMessage = "API Key is invalid or unauthorized. Please check it in Settings."
            default:
                displayMessage = rwError.localizedDescription // More generic error from ReadwiseError
            }
            readwise.currentQuote = nil // Clear quote on error
        } catch {
            print("ContentView: Unhandled error fetching quote: \(error)")
            displayMessage = "An unexpected error occurred while fetching your quote."
            readwise.currentQuote = nil // Clear quote on error
        }
    }
}

#Preview {
    ContentView()
}
