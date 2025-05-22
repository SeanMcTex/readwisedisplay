//
//  ContentView.swift
//  ReadwiseDisplay
//
//  Created by Sean Mc Mains on 5/21/25.
//

import SwiftUI

struct Quote {
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
    
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let horizontalPaddingForQuote = geometry.size.width * 0.1 // For quote text

            ZStack {
                // Layer 1: Background Color
                backgroundColors[currentColorIndex]
                    .edgesIgnoringSafeArea(.all)

                if let quote = readwise.currentQuote {
                    // Layer 2: Quote Text - Vertically Centered
                    VStack {
                        Spacer() // Pushes text down
                        Text(quote.text)
                            .font(.system(size: 90, weight: .light))
                            .minimumScaleFactor(0.2)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, horizontalPaddingForQuote)
                            .foregroundColor(.white)
                        Spacer() // Pushes text up
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow spacers to work

                    // Layer 3: Author and Source - Bottom Right
                    VStack { // Outer VStack to push its content to the bottom
                        Spacer()
                        HStack { // Inner HStack to push its content to the right
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
                            // Padding from the screen edges for author/source
                            .padding(.trailing, 20) // Adjust as needed
                            .padding(.bottom, 20)   // Adjust as needed
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow spacers to work

                } else {
                    // Loading State - Centered
                    VStack {
                        Spacer()
                        Text("Loading quote...")
                            .font(.system(size: 24)) // Give loading text a size
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            // Apply gestures and tasks to the ZStack
            .task {
                do {
                    try await readwise.fetchRandomQuote()
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
        }
    }
}

#Preview {
    ContentView()
}
