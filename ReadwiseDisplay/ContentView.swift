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
    @StateObject private var readwise = ReadwiseService(apiKey: "BOWw9f4lRQX01JMWttONcbAaSWnhpc5p5RyjAo550ns7LOJIb9")
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

                if let quote = readwise.currentQuote {
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

                } else {
                    // Loading State
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
            .task {
                do {
                    try await readwise.fetchRandomQuote()
                    self.timer = Timer.publish(every: quoteRefreshInterval, on: .main, in: .common).autoconnect()
                } catch {
                    print("Error fetching quote on task: \(error)")
                }
            }
            .onTapGesture {
                Task {
                    do {
                        try await readwise.fetchRandomQuote()
                        currentColorIndex = (currentColorIndex + 1) % backgroundColors.count
                    } catch {
                        print("Error fetching quote on tap: \(error)")
                    }
                }
            }
            .onReceive(timer) { _ in
                Task {
                    do {
                        try await readwise.fetchRandomQuote()
                        currentColorIndex = (currentColorIndex + 1) % backgroundColors.count
                    } catch {
                        print("Error fetching quote on timer: \(error)")
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
}

#Preview {
    ContentView()
}
